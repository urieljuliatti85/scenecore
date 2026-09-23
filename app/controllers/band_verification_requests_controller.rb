# A Band Administrator submitting the band's own email for verification.
# Deciding it (approve/reject/resend) belongs to the platform, not the
# band — see Admin::BandVerificationRequestsController.
class BandVerificationRequestsController < ApplicationController
  before_action :set_band

  def create
    band_verification_request = @band.band_verification_requests.build(verification_request_params)

    authorize band_verification_request

    ActiveRecord::Base.transaction do
      # Submitting a new email supersedes the badge's claim about the old
      # one — the badge would otherwise keep asserting an address that no
      # longer has a completed verification behind it.
      @band.update!(verified: false) if @band.verified?
      band_verification_request.save!
    end

    redirect_to band_path(@band, tab: "profile"), notice: "Verification request sent. A SceneCore administrator will review it."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to band_path(@band, tab: "profile"), alert: e.record.errors.full_messages.to_sentence
  end

  private

  def set_band
    @band = Band.find(params[:band_id])
  end

  def verification_request_params
    params.require(:band_verification_request).permit(:email)
  end
end
