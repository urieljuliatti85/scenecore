require "rails_helper"

RSpec.describe "Admin::Analytics", type: :request do
  describe "GET /admin/analytics" do
    it "returns 404 for a regular authenticated user" do
      user = create(:user)
      sign_in user

      get admin_analytics_path

      expect(response).to have_http_status(:not_found)
    end

    it "requires authentication" do
      get admin_analytics_path

      expect(response).to redirect_to(new_user_session_path)
    end

    it "shows a not-configured message for a platform admin when Google Analytics isn't set up" do
      admin = create(:user, :platform_admin)
      allow(GoogleAnalyticsClient).to receive(:configured?).and_return(false)
      sign_in admin

      get admin_analytics_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("isn't configured yet")
    end

    it "shows traffic totals and top pages for a platform admin when configured" do
      admin = create(:user, :platform_admin)
      summary = GoogleAnalyticsClient::Metrics.new(
        active_users: 42,
        sessions: 55,
        page_views: 120,
        top_pages: [ GoogleAnalyticsClient::PageResult.new(path: "/the-testers", views: 30) ]
      )
      allow(GoogleAnalyticsClient).to receive(:configured?).and_return(true)
      allow_any_instance_of(GoogleAnalyticsClient).to receive(:summary).with(days: 30).and_return(summary)
      sign_in admin

      get admin_analytics_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("42")
      expect(response.body).to include("55")
      expect(response.body).to include("120")
      expect(response.body).to include("/the-testers")
    end

    it "shows an error message when Google Analytics is configured but the request fails" do
      admin = create(:user, :platform_admin)
      allow(GoogleAnalyticsClient).to receive(:configured?).and_return(true)
      allow_any_instance_of(GoogleAnalyticsClient).to receive(:summary).and_raise(GoogleAnalyticsClient::Error, "Could not reach Google Analytics: boom")
      sign_in admin

      get admin_analytics_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Could not reach Google Analytics")
    end
  end
end
