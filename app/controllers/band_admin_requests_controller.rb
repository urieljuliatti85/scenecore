# A Band Member asking to be promoted to administrator of their own band,
# and cancelling that request while it is still pending. Deciding it
# (approve/reject) belongs to the platform, not the band — see
# Admin::BandAdminRequestsController.
class BandAdminRequestsController < ApplicationController
  before_action :set_band

  def create
    membership = @band.band_memberships.find_by!(user_id: current_user.id)
    band_admin_request = membership.band_admin_requests.build

    authorize band_admin_request

    if band_admin_request.save
      redirect_to band_path(@band), notice: "Request sent. A SceneCore administrator will review it."
    else
      redirect_to band_path(@band), alert: band_admin_request.errors.full_messages.to_sentence
    end
  rescue ActiveRecord::RecordNotFound
    head :not_found
  end

  def destroy
    membership = @band.band_memberships.find_by!(user_id: current_user.id)
    band_admin_request = membership.band_admin_requests.pending.first

    return head :not_found if band_admin_request.nil?

    authorize band_admin_request, :revoke?
    band_admin_request.revoked!

    redirect_to band_path(@band), notice: "Request withdrawn."
  rescue ActiveRecord::RecordNotFound
    head :not_found
  end

  private

  def set_band
    @band = Band.find(params[:band_id])
  end
end
