require "rails_helper"

RSpec.describe "Admin::BandAdminRequests", type: :request do
  describe "GET /admin/band_admin_requests" do
    it "lists requests for a platform admin" do
      admin = create(:user, :platform_admin)
      requester = create(:user, name: "Hopeful Member")
      create(:band_admin_request, user: requester)
      sign_in admin

      get admin_band_admin_requests_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Hopeful Member")
    end

    it "shows the requester's email, so the admin can verify them off-platform" do
      admin = create(:user, :platform_admin)
      requester = create(:user, email: "hopeful@example.com")
      create(:band_admin_request, user: requester)
      sign_in admin

      get admin_band_admin_requests_path

      expect(response.body).to include("hopeful@example.com")
    end

    it "links the band's name to its admin panel" do
      admin = create(:user, :platform_admin)
      band = create(:band)
      band_admin_request = create(:band_admin_request, band: band)
      sign_in admin

      get admin_band_admin_requests_path

      expect(response.body).to include(band_path(band_admin_request.band))
    end

    it "returns 404 for a regular authenticated user" do
      user = create(:user)
      sign_in user

      get admin_band_admin_requests_path

      expect(response).to have_http_status(:not_found)
    end

    it "requires authentication" do
      get admin_band_admin_requests_path

      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "PATCH /admin/band_admin_requests/:id/approve" do
    it "creates a new administrator membership when the user had none" do
      admin = create(:user, :platform_admin)
      band = create(:band)
      band_admin_request = create(:band_admin_request, band: band)
      sign_in admin

      expect {
        patch approve_admin_band_admin_request_path(band_admin_request)
      }.to change(BandMembership, :count).by(1)

      membership = band.band_memberships.find_by(user: band_admin_request.user)
      expect(membership.role).to eq("administrator")
      expect(band_admin_request.reload.status).to eq("approved")
    end

    it "promotes an existing plain membership instead of duplicating it" do
      admin = create(:user, :platform_admin)
      band = create(:band)
      membership = create(:band_membership, band: band, role: :member)
      band_admin_request = create(:band_admin_request, user: membership.user, band: band)
      sign_in admin

      expect {
        patch approve_admin_band_admin_request_path(band_admin_request)
      }.not_to change(BandMembership, :count)

      expect(membership.reload.role).to eq("administrator")
    end

    it "sends an approval email to the requester" do
      admin = create(:user, :platform_admin)
      band_admin_request = create(:band_admin_request)
      sign_in admin

      expect {
        patch approve_admin_band_admin_request_path(band_admin_request)
      }.to have_enqueued_mail(BandAdminRequestMailer, :approved)
    end

    it "records an admin action log" do
      admin = create(:user, :platform_admin)
      band_admin_request = create(:band_admin_request)
      sign_in admin

      expect {
        patch approve_admin_band_admin_request_path(band_admin_request)
      }.to change(AdminActionLog, :count).by(1)
    end

    it "does not allow a regular user to approve" do
      user = create(:user)
      band_admin_request = create(:band_admin_request)
      sign_in user

      patch approve_admin_band_admin_request_path(band_admin_request)

      expect(band_admin_request.reload.status).to eq("pending")
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PATCH /admin/band_admin_requests/:id/reject" do
    it "marks the request rejected without creating a membership" do
      admin = create(:user, :platform_admin)
      band_admin_request = create(:band_admin_request)
      sign_in admin

      expect {
        patch reject_admin_band_admin_request_path(band_admin_request)
      }.not_to change(BandMembership, :count)

      expect(band_admin_request.reload.status).to eq("rejected")
    end

    it "sends a rejection email to the requester" do
      admin = create(:user, :platform_admin)
      band_admin_request = create(:band_admin_request)
      sign_in admin

      expect {
        patch reject_admin_band_admin_request_path(band_admin_request)
      }.to have_enqueued_mail(BandAdminRequestMailer, :rejected)
    end

    it "does not block the user from requesting again afterwards" do
      admin = create(:user, :platform_admin)
      band_admin_request = create(:band_admin_request)
      sign_in admin
      patch reject_admin_band_admin_request_path(band_admin_request)

      expect(build(:band_admin_request, user: band_admin_request.user, band: band_admin_request.band)).to be_valid
    end
  end
end
