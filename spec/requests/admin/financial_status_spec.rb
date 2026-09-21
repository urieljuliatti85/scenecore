require "rails_helper"

RSpec.describe "Admin::FinancialStatus", type: :request do
  let(:stripe_status) do
    StripePlatformStatus::Result.new(
      secret_key_configured: true,
      mode: :live,
      account: StripePlatformStatus::Account.new(
        reachable: true,
        charges_enabled: true,
        payouts_enabled: true,
        details_submitted: true,
        pending_requirements_count: 0,
        disabled_reason: nil,
        error: nil
      ),
      snapshot_webhook: StripePlatformStatus::Webhook.new(secret_configured: true, endpoint_enabled: true, error: nil),
      connect_webhook: StripePlatformStatus::Webhook.new(secret_configured: true, endpoint_enabled: true, error: nil),
      last_webhook_at: 5.minutes.ago
    )
  end

  before do
    allow(StripePlatformStatus).to receive(:call).and_return(stripe_status)
  end

  describe "GET /admin/financial_status" do
    it "shows Stripe platform, integration and connected account status" do
      admin = create(:user, :platform_admin)
      ready = create(:band, :approved, :payouts_ready, name: "Ready Band")
      create(:band, :approved, name: "Onboarding Band", stripe_connect_status: :onboarding,
                    stripe_connect_account_id: "acct_onboarding")
      create(:band, :approved, name: "Restricted Band", stripe_connect_status: :restricted,
                    stripe_connect_account_id: "acct_restricted")
      create(:band, :approved, name: "Unconnected Band")
      sign_in admin

      get admin_financial_status_path

      document = Nokogiri::HTML(response.body)
      expect(document.at_css("#financial-status").text).to include(
        "Platform account", "Integration health", "Connected accounts", "Bands requiring action"
      )
      expect(document.css("#stripe-pending-bands li").size).to eq(3)
      expect(document.at_css("#stripe-pending-bands").text).to include(
        "Onboarding Band", "Restricted Band", "Unconnected Band"
      )
      expect(document.at_css("#stripe-pending-bands").text).not_to include(ready.name)
      expect(response.body).not_to include("sk_live_", "whsec_")
      expect(document.at_css("a[aria-current='page']").text).to include("Financial")
    end

    it "keeps the page available when Stripe cannot be reached" do
      allow(StripePlatformStatus).to receive(:call).and_return(
        stripe_status.with(
          account: stripe_status.account.with(
            reachable: false,
            charges_enabled: false,
            payouts_enabled: false,
            error: "Stripe could not be reached"
          ),
          snapshot_webhook: stripe_status.snapshot_webhook.with(
            endpoint_enabled: false,
            error: "Stripe could not be reached"
          ),
          connect_webhook: stripe_status.connect_webhook.with(
            endpoint_enabled: false,
            error: "Stripe could not be reached"
          )
        )
      )
      sign_in create(:user, :platform_admin)

      get admin_financial_status_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Stripe could not be reached")
      expect(response.body).to include("Financial status")
    end

    it "returns 404 for a regular authenticated user" do
      sign_in create(:user)

      get admin_financial_status_path

      expect(response).to have_http_status(:not_found)
    end

    it "requires authentication" do
      get admin_financial_status_path

      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
