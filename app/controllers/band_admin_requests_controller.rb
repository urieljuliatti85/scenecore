# Any signed-in user asking to be let in and made an administrator of a
# band, and cancelling that request while it is still pending. Deciding
# it (approve/reject) belongs to the platform, not the band — see
# Admin::BandAdminRequestsController.
class BandAdminRequestsController < ApplicationController
  before_action :set_band

  def create
    band_admin_request = @band.band_admin_requests.build(user: current_user)

    authorize band_admin_request

    if band_admin_request.save
      redirect_to public_band_path(@band.slug), notice: "Request sent. A SceneCore administrator will review it."
    else
      redirect_to public_band_path(@band.slug), alert: band_admin_request.errors.full_messages.to_sentence
    end
  end

  def destroy
    band_admin_request = @band.band_admin_requests.pending.find_by(user_id: current_user.id)

    return head :not_found if band_admin_request.nil?

    authorize band_admin_request, :revoke?
    band_admin_request.revoked!

    redirect_to public_band_path(@band.slug), notice: "Request withdrawn."
  end

  private

  def set_band
    @band = Band.approved.find_by!(slug: params[:slug])
  rescue ActiveRecord::RecordNotFound
    head :not_found
  end
end
