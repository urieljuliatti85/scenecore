require "rails_helper"

RSpec.describe "Admin::Dashboard", type: :request do
  describe "GET /admin" do
    it "shows counts for a platform admin" do
      admin = create(:user, :platform_admin)
      create(:band, :approved)
      create(:band)
      create(:band)
      sign_in admin

      get admin_root_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(">2<")
      expect(response.body).to include(">3<")
    end

    it "accents the band and user cards with their section colours" do
      admin = create(:user, :platform_admin)
      sign_in admin

      get admin_root_path

      cards = Nokogiri::HTML(response.body).css("#platform-counts > div")

      expect(cards.size).to eq(3)
      expect(cards[0].to_html).to include("text-emerald-400")
      expect(cards[1].to_html).to include("text-emerald-400")
      expect(cards[2].to_html).to include("text-sky-400")
    end

    context "traffic section" do
      def stub_analytics(summary)
        allow(GoogleAnalyticsClient).to receive(:configured?).and_return(true)
        allow_any_instance_of(GoogleAnalyticsClient).to receive(:summary).and_return(summary)
      end

      def summary(**overrides)
        GoogleAnalyticsClient::Metrics.new(
          **{
            active_users: 1_742, sessions: 3_210, page_views: 8_140,
            bounce_rate: 0.85, session_duration: 63.0,
            daily_series: [ GoogleAnalyticsClient::DailyPoint.new(date: Date.new(2026, 9, 1), active_users: 10) ],
            channels: [ GoogleAnalyticsClient::BreakdownResult.new(label: "Organic Search", sessions: 536) ],
            top_pages: [ GoogleAnalyticsClient::PageResult.new(path: "/bands", views: 156) ]
          }.merge(overrides)
        )
      end

      it "shows Google Analytics totals alongside the platform counts" do
        stub_analytics(summary)
        sign_in create(:user, :platform_admin)

        get admin_root_path

        expect(response.body).to include("1,742")
        expect(response.body).to include("85%")
        expect(response.body).to include("Organic Search")
      end

      # The counts come from the database and must survive a reporting
      # outage, so a Google Analytics failure may not take the page down.
      it "still shows the platform counts when Google Analytics fails" do
        allow(GoogleAnalyticsClient).to receive(:configured?).and_return(true)
        allow_any_instance_of(GoogleAnalyticsClient)
          .to receive(:summary).and_raise(GoogleAnalyticsClient::Error, "Could not reach Google Analytics")
        create(:band, :approved)
        sign_in create(:user, :platform_admin)

        get admin_root_path

        expect(response).to have_http_status(:ok)
        expect(Nokogiri::HTML(response.body).css("#platform-counts > div").size).to eq(3)
        expect(response.body).to include("Could not reach Google Analytics")
      end

      it "says so when Google Analytics is not configured" do
        allow(GoogleAnalyticsClient).to receive(:configured?).and_return(false)
        sign_in create(:user, :platform_admin)

        get admin_root_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("isn't configured yet")
      end

      # Bar widths are a share of the largest row, so the top row is always
      # full width and the rest read as a proportion of it.
      it "scales each bar against the largest row" do
        stub_analytics(summary(channels: [
          GoogleAnalyticsClient::BreakdownResult.new(label: "Organic Search", sessions: 500),
          GoogleAnalyticsClient::BreakdownResult.new(label: "Direct", sessions: 250)
        ]))
        sign_in create(:user, :platform_admin)

        get admin_root_path

        widths = Nokogiri::HTML(response.body).css("span[style*='width']").map { |n| n["style"] }

        expect(widths).to include("width: 100.0%")
        expect(widths).to include("width: 50.0%")
      end

      it "only offers the day ranges the client accepts" do
        stub_analytics(summary)
        sign_in create(:user, :platform_admin)

        get admin_root_path(days: 999)

        # An unsupported range falls back to the default rather than being
        # passed through to the API.
        expect(response.body).to include("last 30 days")
      end
    end

    it "returns 404 for a regular authenticated user" do
      user = create(:user)
      sign_in user

      get admin_root_path

      expect(response).to have_http_status(:not_found)
    end

    it "requires authentication" do
      get admin_root_path

      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
