class MembershipsController < ApplicationController
  before_action :set_band

  def index
    authorize Membership.new(band: @band), :index?
    @memberships = @band.memberships.includes(:user).order(created_at: :desc)
  end

  private

  def set_band
    @band = Band.find(params[:band_id])
  end
end
