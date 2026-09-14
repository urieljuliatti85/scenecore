class PublicBandsController < ApplicationController
  skip_before_action :authenticate_user!

  def show
    @band = Band.approved.find_by!(slug: params[:slug])
    @albums = @band.albums.published.includes(:tracks)
    @following = current_user.present? && @band.follows.exists?(user: current_user)
    @posts = visible_posts(@band)
  rescue ActiveRecord::RecordNotFound
    head :not_found
  end

  private

  def visible_posts(band)
    visibilities = [ Post.visibilities[:public] ]
    visibilities << Post.visibilities[:followers] if @following

    band.posts.published.where(visibility: visibilities).order(created_at: :desc)
  end
end
