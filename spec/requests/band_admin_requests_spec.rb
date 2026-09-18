require "rails_helper"

RSpec.describe "BandAdminRequests", type: :request do
  describe "POST /bands/:band_id/admin-request" do
    it "lets a Band Member request administrator access" do
      band = create(:band)
      membership = create(:band_membership, band: band, role: :member)
      sign_in membership.user

      expect {
        post band_band_admin_request_path(band)
      }.to change(BandAdminRequest, :count).by(1)

      expect(BandAdminRequest.last.band_membership).to eq(membership)
      expect(response).to redirect_to(band_path(band))
    end

    it "does not let a request stack while one is already pending" do
      band = create(:band)
      membership = create(:band_membership, band: band, role: :member)
      create(:band_admin_request, band_membership: membership)
      sign_in membership.user

      expect {
        post band_band_admin_request_path(band)
      }.not_to change(BandAdminRequest, :count)
    end

    it "does not let an existing administrator request promotion" do
      band = create(:band)
      membership = create(:band_membership, :administrator, band: band)
      sign_in membership.user

      expect {
        post band_band_admin_request_path(band)
      }.not_to change(BandAdminRequest, :count)
    end

    it "returns 404 for a user with no membership in the band" do
      band = create(:band)
      user = create(:user)
      sign_in user

      post band_band_admin_request_path(band)

      expect(response).to have_http_status(:not_found)
    end

    it "requires authentication" do
      band = create(:band)

      post band_band_admin_request_path(band)

      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "DELETE /bands/:band_id/admin-request" do
    it "lets the requester withdraw their own pending request" do
      band = create(:band)
      membership = create(:band_membership, band: band, role: :member)
      band_admin_request = create(:band_admin_request, band_membership: membership)
      sign_in membership.user

      delete band_band_admin_request_path(band)

      expect(band_admin_request.reload.status).to eq("revoked")
      expect(response).to redirect_to(band_path(band))
    end

    it "returns 404 when there is no pending request to withdraw" do
      band = create(:band)
      membership = create(:band_membership, band: band, role: :member)
      sign_in membership.user

      delete band_band_admin_request_path(band)

      expect(response).to have_http_status(:not_found)
    end

    it "does not let another band member withdraw someone else's request" do
      band = create(:band)
      membership = create(:band_membership, band: band, role: :member)
      create(:band_admin_request, band_membership: membership)
      other_member = create(:band_membership, band: band, role: :member)
      sign_in other_member.user

      delete band_band_admin_request_path(band)

      expect(response).to have_http_status(:not_found)
    end
  end
end
