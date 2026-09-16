class PublicAlbumsController < ApplicationController
  skip_before_action :authenticate_user!

  def show
    @band = Band.approved.find_by!(slug: params[:slug])
    @album = @band.albums.published.with_attached_cover.find(params[:id])
    @rating = current_user && @album.ratings.find_by(user: current_user)
  rescue ActiveRecord::RecordNotFound
    render "public_bands/not_found", status: :not_found
  end
end
