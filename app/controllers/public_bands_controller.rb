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
    @albums = @band.albums.published.with_attached_cover.includes(:tracks)
    @following = current_user.present? && @band.follows.exists?(user: current_user)
    @posts = visible_posts(@band)
    @published_tracks_count = @band.tracks.published.count
  rescue ActiveRecord::RecordNotFound
    render "not_found", status: :not_found
  end

  def album
    @band = Band.approved.find_by!(slug: params[:slug])
    @album = @band.albums.published.find(params[:id])
    @tracks = @album.tracks.published.order(:track_number)
  rescue ActiveRecord::RecordNotFound
    render "not_found", status: :not_found
  end

  private

  def visible_posts(band)
    visibilities = [ Post.visibilities[:public] ]
    visibilities << Post.visibilities[:followers] if @following

    band.posts.published.where(visibility: visibilities).order(created_at: :desc)
  end
end
