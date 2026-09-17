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
        top_pages: [ GoogleAnalyticsClient::PageResult.new(path: "/the-testers", views: 30) ],
        daily_series: [ GoogleAnalyticsClient::DailyPoint.new(date: Date.new(2026, 9, 1), active_users: 10, sessions: 12) ],
        channels: [ GoogleAnalyticsClient::BreakdownResult.new(label: "Organic Search", sessions: 20) ],
        devices: [ GoogleAnalyticsClient::BreakdownResult.new(label: "desktop", sessions: 33) ]
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
      expect(response.body).to include("Organic Search")
      expect(response.body).to include("desktop")
    end

    it "defaults to a 30-day range and lets the admin switch to 7 or 90 days" do
      admin = create(:user, :platform_admin)
      summary = GoogleAnalyticsClient::Metrics.new(
        active_users: 1, sessions: 1, page_views: 1, top_pages: [], daily_series: [], channels: [], devices: []
      )
      allow(GoogleAnalyticsClient).to receive(:configured?).and_return(true)
      allow_any_instance_of(GoogleAnalyticsClient).to receive(:summary).with(days: 7).and_return(summary)
      sign_in admin

      get admin_analytics_path(days: 7)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("last 7 days")
    end

    it "falls back to 30 days for an unsupported day range param" do
      admin = create(:user, :platform_admin)
      summary = GoogleAnalyticsClient::Metrics.new(
        active_users: 1, sessions: 1, page_views: 1, top_pages: [], daily_series: [], channels: [], devices: []
      )
      allow(GoogleAnalyticsClient).to receive(:configured?).and_return(true)
      allow_any_instance_of(GoogleAnalyticsClient).to receive(:summary).with(days: 30).and_return(summary)
      sign_in admin

      get admin_analytics_path(days: 999)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("last 30 days")
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
