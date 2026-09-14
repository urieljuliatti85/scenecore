class FollowsController < ApplicationController
  before_action :set_band

  def create
    @follow = @band.follows.find_or_initialize_by(user: current_user)
    authorize @follow

    @follow.save

    redirect_to public_band_path(@band.slug)
  end

  def destroy
    @follow = @band.follows.find_or_initialize_by(user: current_user)
    authorize @follow

    @follow.destroy

    redirect_to public_band_path(@band.slug)
  end

  private

  def set_band
    @band = Band.find(params[:band_id])
  end
end
