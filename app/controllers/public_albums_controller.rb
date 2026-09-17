class PublicAlbumsController < ApplicationController
  skip_before_action :authenticate_user!

  def show
    @band = Band.approved.find_by!(slug: params[:slug])
    @album = @band.albums.published.with_attached_cover.find(params[:id])
    render "public_bands/not_found", status: :not_found and return unless @album.visible_to?(current_user)

    @rating = current_user && @album.ratings.find_by(user: current_user)
    @credited_users = @album.credited_users
  rescue ActiveRecord::RecordNotFound
    render "public_bands/not_found", status: :not_found
  end
end
