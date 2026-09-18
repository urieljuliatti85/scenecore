require "rails_helper"

RSpec.describe "Admin::BandAdminRequests", type: :request do
  describe "GET /admin/band_admin_requests" do
    it "lists requests for a platform admin" do
      admin = create(:user, :platform_admin)
      requester = create(:user, name: "Hopeful Member")
      membership = create(:band_membership, role: :member, user: requester)
      create(:band_admin_request, band_membership: membership)
      sign_in admin

      get admin_band_admin_requests_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Hopeful Member")
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
    it "promotes the membership and marks the request approved" do
      admin = create(:user, :platform_admin)
      membership = create(:band_membership, role: :member)
      band_admin_request = create(:band_admin_request, band_membership: membership)
      sign_in admin

      patch approve_admin_band_admin_request_path(band_admin_request)

      expect(membership.reload.role).to eq("administrator")
      expect(band_admin_request.reload.status).to eq("approved")
    end

    it "sends an approval email to the requester" do
      admin = create(:user, :platform_admin)
      membership = create(:band_membership, role: :member)
      band_admin_request = create(:band_admin_request, band_membership: membership)
      sign_in admin

      expect {
        patch approve_admin_band_admin_request_path(band_admin_request)
      }.to have_enqueued_mail(BandAdminRequestMailer, :approved)
    end

    it "records an admin action log" do
      admin = create(:user, :platform_admin)
      membership = create(:band_membership, role: :member)
      band_admin_request = create(:band_admin_request, band_membership: membership)
      sign_in admin

      expect {
        patch approve_admin_band_admin_request_path(band_admin_request)
      }.to change(AdminActionLog, :count).by(1)
    end

    it "does not allow a regular user to approve" do
      user = create(:user)
      membership = create(:band_membership, role: :member)
      band_admin_request = create(:band_admin_request, band_membership: membership)
      sign_in user

      patch approve_admin_band_admin_request_path(band_admin_request)

      expect(band_admin_request.reload.status).to eq("pending")
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PATCH /admin/band_admin_requests/:id/reject" do
    it "marks the request rejected without changing the membership role" do
      admin = create(:user, :platform_admin)
      membership = create(:band_membership, role: :member)
      band_admin_request = create(:band_admin_request, band_membership: membership)
      sign_in admin

      patch reject_admin_band_admin_request_path(band_admin_request)

      expect(band_admin_request.reload.status).to eq("rejected")
      expect(membership.reload.role).to eq("member")
    end

    it "sends a rejection email to the requester" do
      admin = create(:user, :platform_admin)
      membership = create(:band_membership, role: :member)
      band_admin_request = create(:band_admin_request, band_membership: membership)
      sign_in admin

      expect {
        patch reject_admin_band_admin_request_path(band_admin_request)
      }.to have_enqueued_mail(BandAdminRequestMailer, :rejected)
    end

    it "does not block the member from requesting again afterwards" do
      admin = create(:user, :platform_admin)
      membership = create(:band_membership, role: :member)
      band_admin_request = create(:band_admin_request, band_membership: membership)
      sign_in admin
      patch reject_admin_band_admin_request_path(band_admin_request)

      expect(build(:band_admin_request, band_membership: membership.reload)).to be_valid
    end
  end
end
