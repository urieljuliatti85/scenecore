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
    @events = @band.events.published.upcoming
    @polls = @band.polls.published.order(created_at: :desc)
    @core_sessions = @band.core_sessions.published.order(:starts_at)
  rescue ActiveRecord::RecordNotFound
    render "not_found", status: :not_found
  end

  def subscriptions
    @band = Band.approved.with_attached_photo.find_by!(slug: params[:slug])
    @membership = current_user.present? ? @band.memberships.find_by(user: current_user) : nil
  rescue ActiveRecord::RecordNotFound
    render "not_found", status: :not_found
  end
end
