class PublicBandsController < ApplicationController
  skip_before_action :authenticate_user!

  SORT_OPTIONS = %w[recent followers].freeze

  def index
    @sort = SORT_OPTIONS.include?(params[:sort]) ? params[:sort] : "recent"
    @category = Category.find_by(id: params[:category_id])
    @categories = Category.roots.order(:name)

    bands = Band.approved.with_attached_photo.includes(:followers, :category)
    bands = bands.where(category_id: @category.id) if @category
    bands = bands.to_a
    bands = @sort == "followers" ? bands.sort_by { |band| -band.followers_count } : bands.sort_by(&:created_at).reverse

    @featured_band = bands.first
    @bands = bands.drop(1)
  end

  def show
    @band = Band.approved.with_attached_photo.includes(:category).find_by!(slug: params[:slug])
    @following = current_user.present? && @band.follows.exists?(user: current_user)
    @membership = current_user.present? ? @band.memberships.find_by(user: current_user) : nil

    # Every published item is listed, visible or not — a locked item shows
    # its title with an upgrade prompt instead of disappearing, per
    # docs/band-admin.md §37 ("do not silently hide the existence of
    # content"). Each view decides how to render a locked card by calling
    # `visible_to?`/`required_level` on the record itself.
    @albums = @band.albums.published.with_attached_cover.order(created_at: :desc)
    @posts = @band.posts.published.with_attached_image.includes(comments: :user).order(created_at: :desc)
    commenter_ids = @posts.flat_map { |post| post.comments.map(&:user_id) }.uniq
    @comment_membership_levels = @band.memberships.active.where(user_id: commenter_ids).pluck(:user_id, :level).to_h
    @events = @band.events.published.upcoming
    @polls = @band.polls.published.order(created_at: :desc)
    @core_sessions = @band.core_sessions.published.order(:starts_at)
    @products = @band.products.published.includes(:variants).order(created_at: :desc)
    @core_members_count = @band.memberships.active.core_member.count
    load_band_admin_request
  rescue ActiveRecord::RecordNotFound
    render "not_found", status: :not_found
  end

  def subscriptions
    @band = Band.approved.with_attached_photo.find_by!(slug: params[:slug])
    @membership = current_user.present? ? @band.memberships.find_by(user: current_user) : nil
  rescue ActiveRecord::RecordNotFound
    render "not_found", status: :not_found
  end

  # docs/band-admin.md §17 — Core Members' "permanent supporter page"
  # benefit. Lists active Core Members only: no membership history, and
  # nothing here grants content access on its own (docs/band-admin.md
  # §31's "no permanent access from payment history alone" is about
  # content gating, not this listing).
  def credits
    @band = Band.approved.find_by!(slug: params[:slug])
    @core_members = @band.memberships.active.core_member.includes(:user).order(:created_at)
  rescue ActiveRecord::RecordNotFound
    render "not_found", status: :not_found
  end

  private

  # Backs the "request administrator access" control on the public band
  # page — shown to any signed-in user without their own BandMembership
  # already there, and reflecting a pending request of their own if one
  # exists.
  def load_band_admin_request
    return if current_user.nil?

    @own_band_membership = @band.band_memberships.find_by(user_id: current_user.id)
    @own_pending_band_admin_request = @band.band_admin_requests.pending.find_by(user_id: current_user.id)
  end
end
