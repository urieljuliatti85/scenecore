# The "Verify Your Band" emailed link. Intentionally reachable without
# signing in: it's opened from an inbox, and the token itself (secret,
# 3-day expiry via generates_token_for) is what proves control of the
# address — the same trust model as Devise's own password reset link.
class BandVerificationsController < ApplicationController
  skip_before_action :authenticate_user!

  def show
    band_verification_request = BandVerificationRequest.find_by_token_for(:band_verification, params[:token])

    if band_verification_request.nil?
      render :invalid, status: :unprocessable_entity
      return
    end

    # A token surviving from an already-decided request (verified again,
    # or one superseded by a newer submission — see
    # BandVerificationRequestsController#create) should not silently
    # re-assert the badge.
    unless band_verification_request.email_sent?
      render :invalid, status: :unprocessable_entity
      return
    end

    band_verification_request.verify!
    @band = band_verification_request.band
  end
end
