require "rails_helper"

RSpec.describe "BandAdminRequests", type: :request do
  describe "POST /:slug/admin-request" do
    it "lets a signed-in user with no membership request administrator access" do
      band = create(:band, :approved)
      user = create(:user)
      sign_in user

      expect {
        post band_admin_request_path(band.slug)
      }.to change(BandAdminRequest, :count).by(1)

      band_admin_request = BandAdminRequest.last
      expect(band_admin_request.user).to eq(user)
      expect(band_admin_request.band).to eq(band)
      expect(response).to redirect_to(public_band_path(band.slug))
    end

    it "lets an existing plain Band Member also request it" do
      band = create(:band, :approved)
      membership = create(:band_membership, band: band, role: :member)
      sign_in membership.user

      expect {
        post band_admin_request_path(band.slug)
      }.to change(BandAdminRequest, :count).by(1)
    end

    it "does not let a request stack while one is already pending" do
      band = create(:band, :approved)
      user = create(:user)
      create(:band_admin_request, user: user, band: band)
      sign_in user

      expect {
        post band_admin_request_path(band.slug)
      }.not_to change(BandAdminRequest, :count)
    end

    it "requires authentication" do
      band = create(:band, :approved)

      post band_admin_request_path(band.slug)

      expect(response).to redirect_to(new_user_session_path)
    end

    it "returns 404 for an unapproved band" do
      band = create(:band)
      user = create(:user)
      sign_in user

      post band_admin_request_path(band.slug)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "DELETE /:slug/admin-request" do
    it "lets the requester withdraw their own pending request" do
      band = create(:band, :approved)
      user = create(:user)
      band_admin_request = create(:band_admin_request, user: user, band: band)
      sign_in user

      delete band_admin_request_path(band.slug)

      expect(band_admin_request.reload.status).to eq("revoked")
      expect(response).to redirect_to(public_band_path(band.slug))
    end

    it "returns 404 when there is no pending request to withdraw" do
      band = create(:band, :approved)
      user = create(:user)
      sign_in user

      delete band_admin_request_path(band.slug)

      expect(response).to have_http_status(:not_found)
    end

    it "does not let a different user withdraw someone else's request" do
      band = create(:band, :approved)
      requester = create(:user)
      create(:band_admin_request, user: requester, band: band)
      other_user = create(:user)
      sign_in other_user

      delete band_admin_request_path(band.slug)

      expect(response).to have_http_status(:not_found)
    end
  end
end
