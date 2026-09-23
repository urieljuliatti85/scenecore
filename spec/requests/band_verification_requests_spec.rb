require "rails_helper"

RSpec.describe "BandVerificationRequests", type: :request do
  describe "POST /bands/:band_id/verification_request" do
    it "lets the band's own administrator submit an email for verification" do
      band = create(:band)
      admin = create(:user)
      create(:band_membership, :administrator, band: band, user: admin)
      sign_in admin

      expect {
        post band_verification_request_path(band), params: { band_verification_request: { email: "official@band.example" } }
      }.to change(BandVerificationRequest, :count).by(1)

      request = BandVerificationRequest.last
      expect(request.band).to eq(band)
      expect(request.email).to eq("official@band.example")
      expect(request).to be_pending
      expect(response).to redirect_to(band_path(band, tab: "profile"))
    end

    it "does not let a plain band member submit a request" do
      band = create(:band)
      member = create(:user)
      create(:band_membership, band: band, user: member)
      sign_in member

      expect {
        post band_verification_request_path(band), params: { band_verification_request: { email: "official@band.example" } }
      }.not_to change(BandVerificationRequest, :count)
    end

    it "does not let an administrator of another band submit a request" do
      band = create(:band)
      outsider = create(:user)
      create(:band_membership, :administrator, band: create(:band), user: outsider)
      sign_in outsider

      expect {
        post band_verification_request_path(band), params: { band_verification_request: { email: "official@band.example" } }
      }.not_to change(BandVerificationRequest, :count)
    end

    it "does not let a platform admin without a membership submit a request" do
      band = create(:band)
      sign_in create(:user, :platform_admin)

      expect {
        post band_verification_request_path(band), params: { band_verification_request: { email: "official@band.example" } }
      }.not_to change(BandVerificationRequest, :count)
    end

    it "requires authentication" do
      band = create(:band)

      post band_verification_request_path(band), params: { band_verification_request: { email: "official@band.example" } }

      expect(response).to redirect_to(new_user_session_path)
    end

    it "does not stack a second request while one is already open" do
      band = create(:band)
      admin = create(:user)
      create(:band_membership, :administrator, band: band, user: admin)
      create(:band_verification_request, band: band)
      sign_in admin

      expect {
        post band_verification_request_path(band), params: { band_verification_request: { email: "second@band.example" } }
      }.not_to change(BandVerificationRequest, :count)

      expect(flash[:alert]).to be_present
    end

    # The badge asserts one specific address; submitting a new one means
    # the old verification no longer applies (docs/product.md §5).
    it "revokes the current verified badge when a new email is submitted" do
      band = create(:band, verified: true)
      admin = create(:user)
      create(:band_membership, :administrator, band: band, user: admin)
      sign_in admin

      post band_verification_request_path(band), params: { band_verification_request: { email: "new@band.example" } }

      expect(band.reload).not_to be_verified
    end
  end
end
