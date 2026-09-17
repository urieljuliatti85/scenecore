class BandsController < ApplicationController
  before_action :set_band_for_member_actions, only: [ :show, :edit, :update ]
  before_action :set_band_for_admin_actions, only: [ :approve, :reject, :suspend, :reactivate, :feature, :unfeature ]

  def index
    @bands = policy_scope(Band)
  end

  def new
    @band = Band.new
    authorize @band

    unless PlatformSetting.current.band_signups_enabled?
      redirect_to bands_path, alert: "Band sign-ups are currently closed."
    end
  end

  # Artist lookup used to prefill the new-band form. Authorized as a band
  # creation so it can't be used as an open proxy to Spotify's API by
  # anyone who is not allowed to create a band in the first place.
  def search
    authorize Band.new, :create?

    return render json: [] unless PlatformSetting.current.band_signups_enabled?

    results = SpotifyClient.new.search_artists(params[:q])
    render json: results.map(&:to_h)
  rescue SpotifyClient::Error
    render json: { error: "Spotify search is unavailable right now." }, status: :bad_gateway
  end

  def create
    @band = Band.new(band_params)
    authorize @band

    unless PlatformSetting.current.band_signups_enabled?
      return redirect_to bands_path, alert: "Band sign-ups are currently closed."
    end

    ActiveRecord::Base.transaction do
      @band.save!
      @band.band_memberships.create!(user: current_user, role: :administrator)
    end

    attach_spotify_photo(params[:spotify_image_url])

    redirect_to @band, notice: "Band created. Awaiting platform approval."
  rescue ActiveRecord::RecordInvalid
    render :new, status: :unprocessable_entity
  end

  # The panel is split into tabs so a band is not handed every album, post,
  # show and poll at once. The manage tabs open in the same panel rather
  # than navigating away, though each still has its own page for deep links
  # and for the forms that live there.
  CONTENT_TABS = %w[overview music posts shows community].freeze
  MANAGE_TABS = %w[profile members supporters products orders payments].freeze
  TABS = (CONTENT_TABS + MANAGE_TABS).freeze

  def show
    @tab = TABS.include?(params[:tab]) ? params[:tab] : TABS.first
    load_manage_tab if MANAGE_TABS.include?(@tab)
    @albums = @band.albums.with_attached_cover
    @posts = @band.posts.order(created_at: :desc)
    @events = @band.events.chronological
    @polls = @band.polls.order(created_at: :desc)
    @core_sessions = @band.core_sessions.order(:starts_at)

    if policy(@band).show?
      active_memberships = @band.memberships.active
      @membership_counts = Membership::LEVELS.index_with { |level| active_memberships.where(level: level).count }
      @new_members_this_month = @band.memberships.where(created_at: Time.current.beginning_of_month..).count
      @total_active_members = @membership_counts.values.sum
      @monthly_recurring_revenue_cents = @membership_counts.sum { |level, count| Membership::PRICES_IN_CENTS[level] * count }
      @new_members_by_month = 5.downto(0).to_h do |months_ago|
        month = months_ago.months.ago.beginning_of_month
        [ month, @band.memberships.where(created_at: month..month.end_of_month).count ]
      end
    end
  end

  def edit
  end

  def update
    if @band.update(band_params)
      redirect_to @band, notice: "Band updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def approve
    @band.update!(status: :approved)
    log_admin_action("approve_band")
    redirect_to @band, notice: "Band approved."
  end

  def reject
    @band.update!(status: :rejected)
    log_admin_action("reject_band")
    redirect_to @band, notice: "Band rejected."
  end

  def suspend
    @band.update!(status: :suspended)
    log_admin_action("suspend_band")
    redirect_to @band, notice: "Band suspended."
  end

  def reactivate
    @band.update!(status: :approved)
    log_admin_action("reactivate_band")
    redirect_to @band, notice: "Band reactivated."
  end

  def feature
    @band.feature!
    log_admin_action("feature_band")
    redirect_to @band, notice: "Band featured on the home page."
  end

  def unfeature
    @band.unfeature!
    log_admin_action("unfeature_band")
    redirect_to @band, notice: "Band removed from the home page."
  end

  private

  # Each manage tab needs what its own controller loads. Authorization is
  # the same policy those controllers check, applied here too so opening a
  # tab can never show more than visiting the page would.
  def load_manage_tab
    case @tab
    when "members"
      authorize BandMembership.new(band: @band), :index?, policy_class: BandMembershipPolicy
      @band_memberships = @band.band_memberships.includes(:user)
    when "supporters"
      authorize Membership.new(band: @band), :index?, policy_class: MembershipPolicy
      @supporter_memberships = @band.memberships.includes(:user).order(created_at: :desc)
    when "products"
      authorize @band, :index?, policy_class: ProductPolicy
      @products = @band.products.includes(:variants).order(created_at: :desc)
    when "orders"
      authorize @band, :update?, policy_class: BandPolicy
      # Orders the band still owes goods on come first: that is the work.
      # The rest stay visible below as a record of what has been sold.
      @orders_awaiting = @band.orders.awaiting_band.includes(:order_items, :shipping_address)
      @orders_settled = @band.orders.where.not(status: [ :paid, :processing ])
                             .includes(:order_items).order(created_at: :desc)
    when "payments"
      authorize @band, :update?, policy_class: BandPolicy
      @active_subscribers = @band.subscriptions.where(status: Subscription::BILLING_STATUSES).count
      @published_products = @band.products.published.count
    when "profile"
      authorize @band, :update?, policy_class: BandPolicy
    end
  end

  def log_admin_action(action)
    AdminActionLog.create!(actor: current_user, action: action, subject: @band)
  end

  # The band is already saved by this point, so a Spotify image that
  # can't be fetched leaves it without a photo rather than failing the
  # sign-up — the band is the thing worth keeping, the photo is a
  # convenience the user can upload later.
  def attach_spotify_photo(image_url)
    return if image_url.blank? || @band.photo.attached?

    image = RemoteImageFetcher.new.call(image_url)
    @band.photo.attach(io: image.io, filename: image.filename, content_type: image.content_type)
  rescue RemoteImageFetcher::Error
    nil
  end

  # show/edit/update rely on band membership (or platform admin); anyone
  # else gets a plain 404 response (not a raised exception, which upsets
  # the session/cookie handling for the rest of the request cycle), so
  # band existence/privacy isn't leaked via a 403.
  def set_band_for_member_actions
    @band = Band.find(params[:id])

    unless BandPolicy.new(current_user, @band).show?
      head :not_found
      return
    end

    authorize @band if action_name.in?(%w[edit update])
  end

  def set_band_for_admin_actions
    @band = Band.find(params[:id])
    authorize @band
  end

  def band_params
    params.require(:band).permit(:name, :description, :photo, :category_id, :country_code,
      :spotify_url, :youtube_url, :instagram_url, :bandcamp_url, :website_url)
  end
end
