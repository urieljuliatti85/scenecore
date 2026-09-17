require "rails_helper"

RSpec.describe StripeConnectOnboardingResolver do
  let(:accounts_service) { instance_double(Stripe::V2::Core::AccountService) }
  let(:account_links_service) { instance_double(Stripe::V2::Core::AccountLinkService) }
  let(:core) { instance_double(Stripe::V2::CoreService, accounts: accounts_service, account_links: account_links_service) }
  let(:v2) { instance_double(Stripe::V2Services, core: core) }
  let(:stripe_client) { instance_double(Stripe::StripeClient, v2: v2) }
  let(:link) { instance_double(Stripe::V2::Core::AccountLink, url: "https://connect.stripe.com/setup/x") }

  before do
    allow(StripeClient).to receive(:instance).and_return(stripe_client)
    allow(account_links_service).to receive(:create).and_return(link)
  end

  def resolve(band, contact_email: "admin@example.com")
    described_class.resolve(
      band,
      contact_email: contact_email,
      return_url: "https://app.test/return",
      refresh_url: "https://app.test/refresh"
    )
  end

  describe ".resolve" do
    it "creates a connected account and persists its id when the band has none" do
      band = create(:band, stripe_connect_account_id: nil)
      allow(accounts_service).to receive(:create).and_return(double(id: "acct_new"))

      expect(resolve(band)).to eq("https://connect.stripe.com/setup/x")
      expect(band.reload.stripe_connect_account_id).to eq("acct_new")
      expect(band).to be_stripe_connect_onboarding
    end

    # Stripe rejects v1 account creation for new integrations, and the v2
    # shape replaces `type: "express"` with three independent dimensions.
    it "creates the account through the v2 API" do
      band = create(:band, stripe_connect_account_id: nil)
      allow(accounts_service).to receive(:create).and_return(double(id: "acct_new"))

      resolve(band)

      expect(accounts_service).to have_received(:create).with(
        hash_including(
          contact_email: "admin@example.com",
          dashboard: "express",
          defaults: {
            responsibilities: {
              fees_collector: "application",
              losses_collector: "application"
            }
          }
        )
      )
    end

    # SceneCore is merchant of record and the band receives transfers, so
    # the account needs the transfer capability and not card_payments —
    # requesting the latter would lengthen onboarding for something the
    # band never uses.
    it "requests the transfer capability rather than card payments" do
      band = create(:band, stripe_connect_account_id: nil)
      allow(accounts_service).to receive(:create).and_return(double(id: "acct_new"))

      resolve(band)

      expect(accounts_service).to have_received(:create) do |args|
        recipient = args[:configuration][:recipient]

        expect(recipient[:capabilities][:stripe_balance][:stripe_transfers]).to eq(requested: true)
        expect(args[:configuration]).not_to have_key(:merchant)
      end
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

      expect(account_links_service).to have_received(:create) do |args|
        onboarding = args[:use_case][:account_onboarding]

        expect(args[:use_case][:type]).to eq("account_onboarding")
        expect(onboarding[:configurations]).to eq([ "recipient" ])
        expect(onboarding[:return_url]).to eq("https://app.test/return")
        expect(onboarding[:refresh_url]).to eq("https://app.test/refresh")
      end
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
