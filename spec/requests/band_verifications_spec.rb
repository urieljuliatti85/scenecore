require "rails_helper"

RSpec.describe "BandVerifications", type: :request do
  describe "GET /band-verification/:token" do
    it "verifies the band and the request when the token is valid" do
      request = create(:band_verification_request, :email_sent)
      token = request.generate_token_for(:band_verification)

      get band_verification_path(token: token)

      expect(response).to have_http_status(:ok)
      expect(request.reload).to be_verified
      expect(request.band.reload).to be_verified
    end

    it "does not require signing in" do
      request = create(:band_verification_request, :email_sent)
      token = request.generate_token_for(:band_verification)

      get band_verification_path(token: token)

      expect(response).to have_http_status(:ok)
    end

    it "shows an error page for a garbage token" do
      get band_verification_path(token: "not-a-real-token")

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "shows an error page for an expired token, and does not verify the band" do
      request = create(:band_verification_request, :email_sent)
      token = travel_to(4.days.ago) { request.generate_token_for(:band_verification) }

      get band_verification_path(token: token)

      expect(response).to have_http_status(:unprocessable_content)
      expect(request.reload).to be_email_sent
      expect(request.band.reload).not_to be_verified
    end

    # A request that never left pending has no emailed link, so the token
    # under it (if one is somehow presented) must not silently verify —
    # the admin's review is what's supposed to gate this.
    it "does not verify a request that is still pending (never approved)" do
      request = create(:band_verification_request)
      token = request.generate_token_for(:band_verification)

      get band_verification_path(token: token)

      expect(response).to have_http_status(:unprocessable_content)
      expect(request.reload).to be_pending
      expect(request.band.reload).not_to be_verified
    end

    it "does not re-verify an already-verified request" do
      request = create(:band_verification_request, :verified)
      token = request.generate_token_for(:band_verification)

      get band_verification_path(token: token)

      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
