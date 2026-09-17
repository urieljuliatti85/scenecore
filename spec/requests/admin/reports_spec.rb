require "rails_helper"

RSpec.describe "Admin::Reports", type: :request do
  describe "GET /admin/reports" do
    it "lists reports for a platform admin" do
      admin = create(:user, :platform_admin)
      post = create(:post, title: "Reported Post")
      create(:report, reportable: post, reason: "This is spam")
      sign_in admin

      get admin_reports_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("This is spam")
      expect(response.body).to include("Reported Post")
    end

    it "returns 404 for a regular authenticated user" do
      user = create(:user)
      sign_in user

      get admin_reports_path

      expect(response).to have_http_status(:not_found)
    end

    it "requires authentication" do
      get admin_reports_path

      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "PATCH /admin/reports/:id/resolve" do
    it "marks the report as resolved" do
      admin = create(:user, :platform_admin)
      report = create(:report)
      sign_in admin

      patch resolve_admin_report_path(report)

      expect(report.reload.status).to eq("resolved")
    end
  end

  describe "PATCH /admin/reports/:id/dismiss" do
    it "marks the report as dismissed" do
      admin = create(:user, :platform_admin)
      report = create(:report)
      sign_in admin

      patch dismiss_admin_report_path(report)

      expect(report.reload.status).to eq("dismissed")
    end
  end
end
