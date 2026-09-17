require "rails_helper"

RSpec.describe "StripeConnectAccounts", type: :request do
  let(:accounts_service) { instance_double(Stripe::V2::Core::AccountService) }
  let(:account_links_service) { instance_double(Stripe::V2::Core::AccountLinkService) }
  let(:core) { instance_double(Stripe::V2::CoreService, accounts: accounts_service, account_links: account_links_service) }
  let(:v2) { instance_double(Stripe::V2Services, core: core) }
  let(:stripe_client) { instance_double(Stripe::StripeClient, v2: v2) }

  before do
    allow(StripeClient).to receive(:instance).and_return(stripe_client)
    allow(accounts_service).to receive(:create).and_return(double(id: "acct_new"))
    allow(accounts_service).to receive(:update)
    allow(account_links_service).to receive(:create)
      .and_return(double(url: "https://connect.stripe.com/setup/x"))
  end

  describe "POST /bands/:band_id/stripe-connect" do
    it "redirects a band administrator to Stripe onboarding" do
      band = create(:band)
      admin = create(:user)
      create(:band_membership, :administrator, band: band, user: admin)
      sign_in admin

      post band_stripe_connect_account_path(band)

      expect(response).to redirect_to("https://connect.stripe.com/setup/x")
      expect(band.reload.stripe_connect_account_id).to eq("acct_new")
    end

    it "does not let a plain band member start onboarding" do
      band = create(:band)
      member = create(:user)
      create(:band_membership, band: band, user: member)
      sign_in member

      post band_stripe_connect_account_path(band)

      expect(response).not_to redirect_to("https://connect.stripe.com/setup/x")
      expect(band.reload.stripe_connect_account_id).to be_nil
    end

    it "does not let a non-member start onboarding for someone else's band" do
      band = create(:band)
      sign_in create(:user)

      post band_stripe_connect_account_path(band)

      expect(band.reload.stripe_connect_account_id).to be_nil
      expect(accounts_service).not_to have_received(:create)
    end

    it "does not let a signed-out visitor start onboarding" do
      band = create(:band)

      post band_stripe_connect_account_path(band)

      expect(band.reload.stripe_connect_account_id).to be_nil
    end

    it "shows an alert instead of failing when Stripe rejects the request" do
      band = create(:band)
      admin = create(:user)
      create(:band_membership, :administrator, band: band, user: admin)
      allow(accounts_service).to receive(:create).and_raise(Stripe::APIConnectionError.new("network down"))
      sign_in admin

      post band_stripe_connect_account_path(band)

      expect(response).to redirect_to(edit_band_path(band))
      expect(flash[:alert]).to be_present
    end
  end

  # Stripe sends the band back here with a GET when an onboarding link
  # expires, so it must mint a fresh link rather than 404.
  describe "GET /bands/:band_id/stripe-connect/new" do
    it "redirects a band administrator back into Stripe onboarding" do
      band = create(:band, stripe_connect_account_id: "acct_existing")
      admin = create(:user)
      create(:band_membership, :administrator, band: band, user: admin)
      sign_in admin

      get new_band_stripe_connect_account_path(band)

      expect(response).to redirect_to("https://connect.stripe.com/setup/x")
      expect(accounts_service).to have_received(:update).with(
        "acct_existing",
        configuration: StripeConnectOnboardingResolver::CONNECT_CONFIGURATION
      )
      expect(account_links_service).to have_received(:create).with(hash_including(account: "acct_existing"))
    end

    it "does not let a non-member refresh onboarding" do
      band = create(:band, stripe_connect_account_id: "acct_existing")
      sign_in create(:user)

      get new_band_stripe_connect_account_path(band)

      expect(account_links_service).not_to have_received(:create)
    end
  end
end
