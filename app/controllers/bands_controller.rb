class BandsController < ApplicationController
  before_action :set_band_for_member_actions, only: [ :show, :edit, :update ]
  before_action :set_band_for_admin_actions, only: [ :approve, :reject, :suspend, :reactivate ]

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

    redirect_to @band, notice: "Band created. Awaiting platform approval."
  rescue ActiveRecord::RecordInvalid
    render :new, status: :unprocessable_entity
  end

  def show
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

  private

  def log_admin_action(action)
    AdminActionLog.create!(actor: current_user, action: action, subject: @band)
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
    params.require(:band).permit(:name, :description, :photo, :category_id,
      :spotify_url, :youtube_url, :instagram_url, :bandcamp_url, :website_url)
  end
end
