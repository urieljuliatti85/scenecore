class PublicBandsController < ApplicationController
  skip_before_action :authenticate_user!

  def show
    @band = Band.approved.find_by!(slug: params[:slug])
    @albums = @band.albums.published.includes(:tracks)
    @following = current_user.present? && @band.follows.exists?(user: current_user)
  rescue ActiveRecord::RecordNotFound
    head :not_found
  end
end
