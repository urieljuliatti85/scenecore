class BandVerificationMailer < ApplicationMailer
  def verify(band_verification_request)
    @band_verification_request = band_verification_request
    @band = band_verification_request.band
    @token = band_verification_request.generate_token_for(:band_verification)

    mail(to: @band_verification_request.email, subject: "Verify Your Band on SceneCore")
  end
end
