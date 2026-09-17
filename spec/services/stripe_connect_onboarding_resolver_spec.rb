require "rails_helper"

RSpec.describe StripeConnectOnboardingResolver do
  let(:accounts_service) { instance_double(Stripe::AccountService) }
  let(:account_links_service) { instance_double(Stripe::AccountLinkService) }
  let(:v1) { instance_double(Stripe::V1Services, accounts: accounts_service, account_links: account_links_service) }
  let(:stripe_client) { instance_double(Stripe::StripeClient, v1: v1) }
  let(:link) { instance_double(Stripe::AccountLink, url: "https://connect.stripe.com/setup/x") }

  before do
    allow(StripeClient).to receive(:instance).and_return(stripe_client)
    allow(account_links_service).to receive(:create).and_return(link)
  end

  def resolve(band)
    described_class.resolve(band, return_url: "https://app.test/return", refresh_url: "https://app.test/refresh")
  end

  describe ".resolve" do
    it "creates a connected account and persists its id when the band has none" do
      band = create(:band, stripe_connect_account_id: nil)
      allow(accounts_service).to receive(:create).and_return(instance_double(Stripe::Account, id: "acct_new"))

      expect(resolve(band)).to eq("https://connect.stripe.com/setup/x")
      expect(band.reload.stripe_connect_account_id).to eq("acct_new")
      expect(band).to be_stripe_connect_onboarding
    end

    it "reuses the existing connected account instead of creating a second one" do
      band = create(:band, stripe_connect_account_id: "acct_existing", stripe_connect_status: :onboarding)
      allow(accounts_service).to receive(:create)

      resolve(band)

      expect(accounts_service).not_to have_received(:create)
      expect(account_links_service).to have_received(:create).with(hash_including(account: "acct_existing"))
    end

    it "requests an onboarding link with the given return and refresh urls" do
      band = create(:band, stripe_connect_account_id: "acct_existing")

      resolve(band)

      expect(account_links_service).to have_received(:create).with(
        hash_including(
          type: "account_onboarding",
          return_url: "https://app.test/return",
          refresh_url: "https://app.test/refresh"
        )
      )
    end

    # A band that already finished onboarding may revisit the link (e.g.
    # to update details); that must not knock a live account back to
    # "onboarding" and close its store.
    it "does not downgrade an already active status" do
      band = create(:band, stripe_connect_account_id: "acct_existing", stripe_connect_status: :active)

      resolve(band)

      expect(band.reload).to be_stripe_connect_active
    end

    it "wraps a Stripe error" do
      band = create(:band, stripe_connect_account_id: nil)
      allow(accounts_service).to receive(:create).and_raise(Stripe::APIConnectionError.new("network down"))

      expect { resolve(band) }.to raise_error(described_class::Error)
    end
  end
end
