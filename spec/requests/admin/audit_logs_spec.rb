require "rails_helper"

RSpec.describe "Admin::AuditLogs", type: :request do
  describe "GET /admin/audit_logs" do
    it "lists logged actions for a platform admin" do
      admin = create(:user, :platform_admin)
      band = create(:band)
      AdminActionLog.create!(actor: admin, action: "moderate_unpublish_album", subject: create(:album, band: band))
      sign_in admin

      get admin_audit_logs_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Moderate unpublish album")
    end

    it "returns 404 for a regular authenticated user" do
      user = create(:user)
      sign_in user

      get admin_audit_logs_path

      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 for a band administrator who is not a platform admin" do
      user = create(:user)
      band = create(:band)
      create(:band_membership, :administrator, band: band, user: user)
      sign_in user

      get admin_audit_logs_path

      expect(response).to have_http_status(:not_found)
    end

    it "requires authentication" do
      get admin_audit_logs_path

      expect(response).to redirect_to(new_user_session_path)
    end

    it "shows the most recent action first" do
      admin = create(:user, :platform_admin)
      band = create(:band)
      older_post = create(:post, band: band, title: "Older Post")
      newer_post = create(:post, band: band, title: "Newer Post")
      AdminActionLog.create!(actor: admin, action: "moderate_unpublish_post", subject: older_post, created_at: 2.days.ago)
      AdminActionLog.create!(actor: admin, action: "moderate_delete_post", subject: newer_post, created_at: 1.hour.ago)
      sign_in admin

      get admin_audit_logs_path

      body_after_first = response.body.split("Moderate delete post").last
      expect(body_after_first).to include("Moderate unpublish post")
    end
  end
end
