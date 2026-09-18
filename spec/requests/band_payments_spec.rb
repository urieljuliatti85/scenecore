require "rails_helper"

RSpec.describe "Band payments", type: :request do
  let(:band) { create(:band, :approved, name: "The Testers") }
  let(:admin) { create(:user) }
  let(:financial_summary) do
    StripeConnectedAccountFinancials::Summary.new(
      balances: [ StripeConnectedAccountFinancials::Balance.new(
        currency: "usd", available_cents: 12_500, pending_cents: 3_000
      ) ],
      next_payout: StripeConnectedAccountFinancials::Payout.new(
        currency: "usd", amount_cents: 8_000, arrival_at: Time.zone.local(2026, 9, 25)
      )
    )
  end

  before do
    allow(StripeConnectedAccountFinancials).to receive(:call).and_return(financial_summary)
  end

  def sign_in_as_administrator
    create(:band_membership, :administrator, band: band, user: admin)
    sign_in admin
  end

  describe "authorization" do
    it "requires signing in" do
      get band_payments_path(band)

      expect(response).to redirect_to(new_user_session_path)
    end

    # Payment settings are the band's own money, so a plain member sees
    # nothing of them.
    it "refuses a member who is not an administrator" do
      member = create(:user)
      create(:band_membership, band: band, user: member, role: :member)
      sign_in member

      get band_payments_path(band)

      expect(response).to redirect_to(root_path)
    end

    it "refuses another band's administrator" do
      outsider = create(:user)
      create(:band_membership, :administrator, band: create(:band), user: outsider)
      sign_in outsider

      get band_payments_path(band)

      expect(response).to redirect_to(root_path)
    end

    it "lets this band's administrator in" do
      sign_in_as_administrator

      get band_payments_path(band)

      expect(response).to have_http_status(:ok)
    end
  end

  # Each Connect status leaves the band in a different position, so the page
  # names which one rather than printing the enum.
  describe "connect status" do
    before { sign_in_as_administrator }

    it "explains that Stripe is not connected yet" do
      get band_payments_path(band)

      expect(response.body).to include("haven&#39;t connected Stripe yet")
    end

    it "explains an unfinished onboarding" do
      band.update!(stripe_connect_status: :onboarding, stripe_connect_account_id: "acct_1")

      get band_payments_path(band)

      expect(response.body).to include("still needs some details")
    end

    it "explains a restricted account" do
      band.update!(stripe_connect_status: :restricted, stripe_connect_account_id: "acct_1")

      get band_payments_path(band)

      expect(response.body).to include("has restricted your account")
    end

    it "confirms an active account and offers its financial dashboard" do
      band.update!(stripe_connect_status: :active, stripe_connect_account_id: "acct_1")

      get band_payments_path(band)

      expect(response.body).to include("Stripe account verified")
      expect(response.body).to include("Open financial dashboard")
    end
  end

  # Status normally arrives by webhook. A webhook that never lands would
  # otherwise strand the band on "onboarding" with checkout blocked and no
  # way to correct it from the UI.
  describe "refreshing the status from Stripe" do
    let(:accounts_service) { instance_double(Stripe::V2::Core::AccountService) }
    let(:core) { instance_double(Stripe::V2::CoreService, accounts: accounts_service) }
    let(:v2) { instance_double(Stripe::V2Services, core: core) }
    let(:stripe_client) { instance_double(Stripe::StripeClient, v2: v2) }

    before do
      allow(StripeClient).to receive(:instance).and_return(stripe_client)
      sign_in_as_administrator
    end

    def active_account
      double(
        id: "acct_1",
        configuration: double(
          recipient: double(
            capabilities: double(
              stripe_balance: double(stripe_transfers: double(status: "active"))
            )
          )
        )
      )
    end

    it "promotes the band and renders the new state in the same response" do
      band.update!(stripe_connect_status: :onboarding, stripe_connect_account_id: "acct_1")
      allow(accounts_service).to receive(:retrieve).and_return(active_account)

      get band_payments_path(band)

      expect(band.reload).to be_stripe_connect_active
      expect(response.body).to include("Stripe account verified")
    end

    # Only the state where the answer is expected to change is worth a call
    # on every visit.
    it "does not ask Stripe when the account is already active" do
      band.update!(stripe_connect_status: :active, stripe_connect_account_id: "acct_1")
      allow(accounts_service).to receive(:retrieve)

      get band_payments_path(band)

      expect(accounts_service).not_to have_received(:retrieve)
    end

    it "does not ask Stripe when no account exists yet" do
      allow(accounts_service).to receive(:retrieve)

      get band_payments_path(band)

      expect(accounts_service).not_to have_received(:retrieve)
    end

    # This page is where the band reads what is blocked, so it has to render
    # even when Stripe cannot be reached.
    it "still renders when Stripe is unreachable" do
      band.update!(stripe_connect_status: :onboarding, stripe_connect_account_id: "acct_1")
      allow(accounts_service).to receive(:retrieve).and_raise(Stripe::APIConnectionError.new("down"))

      get band_payments_path(band)

      expect(response).to have_http_status(:ok)
      expect(band.reload).to be_stripe_connect_onboarding
      expect(response.body).to include("still needs some details")
    end
  end

  describe "what is blocked" do
    before { sign_in_as_administrator }

    # Memberships began routing payment to the connected account too, so a
    # band without one loses both, not just the Store.
    it "names memberships and the Store while the account is not ready" do
      get band_payments_path(band)

      expect(response.body).to include("What this blocks")
      expect(response.body).to include("can't start a membership")
      expect(response.body).to include("can't buy from your Store")
    end

    it "says nothing is blocked once the account is active" do
      band.update!(stripe_connect_status: :active, stripe_connect_account_id: "acct_1")

      get band_payments_path(band)

      expect(response.body).not_to include("What this blocks")
    end

    # A band with people already waiting is in a different position from one
    # with nothing set up, so the page counts rather than generalising.
    it "counts the subscribers and products affected" do
      create(:subscription, :active, band: band, user: create(:user))
      create(:product, :published, band: band)

      get band_payments_path(band)

      expect(response.body).to include("1 existing subscriber")
      expect(response.body).to include("1 published product")
    end
  end

  describe "the split" do
    before { sign_in_as_administrator }

    it "quotes what the band keeps from each revenue stream" do
      get band_payments_path(band)

      expect(response.body).to include("85%")
      expect(response.body).to include("90%")
    end
  end

  describe "financial overview" do
    before do
      sign_in_as_administrator
      band.update!(stripe_connect_status: :active, stripe_connect_account_id: "acct_1")
    end

    it "shows available and pending balance with the next payout" do
      get band_payments_path(band)

      expect(response.body).to include("USD 125.00")
      expect(response.body).to include("USD 30.00 pending")
      expect(response.body).to include("USD 80.00")
      expect(response.body).to include("September 25, 2026")
    end

    it "explains when there is no payout scheduled" do
      allow(StripeConnectedAccountFinancials).to receive(:call).and_return(
        financial_summary.with(next_payout: nil)
      )

      get band_payments_path(band)

      expect(response.body).to include("No payout scheduled")
    end

    it "keeps the page available when Stripe financials cannot be read" do
      allow(StripeConnectedAccountFinancials).to receive(:call)
        .and_raise(StripeConnectedAccountFinancials::Error, "down")

      get band_payments_path(band)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Financial information is temporarily unavailable")
      expect(response.body).to include("Open financial dashboard")
    end

    it "also shows the financial overview in the band's Payments tab" do
      get band_path(band, tab: "payments")

      expect(response.body).to include("USD 125.00")
      expect(response.body).to include("Open financial dashboard")
    end
  end

  describe "opening the Stripe dashboard" do
    before do
      allow(StripeExpressDashboardLink).to receive(:call)
        .and_return("https://connect.stripe.com/express/test")
    end

    it "requires signing in" do
      post stripe_dashboard_band_payments_path(band)

      expect(response).to redirect_to(new_user_session_path)
    end

    it "refuses another band's administrator" do
      outsider = create(:user)
      create(:band_membership, :administrator, band: create(:band), user: outsider)
      sign_in outsider

      post stripe_dashboard_band_payments_path(band)

      expect(response).to redirect_to(root_path)
      expect(StripeExpressDashboardLink).not_to have_received(:call)
    end

    it "redirects this band's administrator to a fresh Express link" do
      sign_in_as_administrator
      band.update!(stripe_connect_status: :active, stripe_connect_account_id: "acct_1")

      post stripe_dashboard_band_payments_path(band)

      expect(response).to redirect_to("https://connect.stripe.com/express/test")
      expect(StripeExpressDashboardLink).to have_received(:call).with(band)
    end

    it "returns safely to Payments when Stripe cannot create the link" do
      sign_in_as_administrator
      band.update!(stripe_connect_status: :active, stripe_connect_account_id: "acct_1")
      allow(StripeExpressDashboardLink).to receive(:call)
        .and_raise(StripeExpressDashboardLink::Error, "Stripe dashboard unavailable")

      post stripe_dashboard_band_payments_path(band)

      expect(response).to redirect_to(band_payments_path(band))
      expect(flash[:alert]).to eq("Stripe dashboard unavailable")
    end
  end

  describe "discoverability" do
    before { sign_in_as_administrator }

    # A band that sells no merch has no reason to open Products, which is
    # where the only Connect prompt used to live.
    it "is reachable from the band panel" do
      get band_path(band)

      expect(response.body).to include("tab=payments")
    end

    it "flags the panel tab while payments are not set up" do
      get band_path(band)

      tab = Nokogiri::HTML(response.body).css("a[href*='tab=payments']").first

      expect(tab["class"]).to include("yellow")
    end

    it "stops flagging it once the account is active" do
      band.update!(stripe_connect_status: :active, stripe_connect_account_id: "acct_1")

      get band_path(band)

      tab = Nokogiri::HTML(response.body).css("a[href*='tab=payments']").first

      expect(tab["class"]).not_to include("yellow")
    end

    # The dedicated page stays for deep links and for anyone landing on it
    # directly, so the panel tab is an additional way in, not a replacement.
    it "still serves its own page" do
      get band_payments_path(band)

      expect(response).to have_http_status(:ok)
    end
  end
end
