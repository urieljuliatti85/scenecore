require "rails_helper"

RSpec.describe StripeConnectStatusRefresher do
  let(:accounts_service) { instance_double(Stripe::V2::Core::AccountService) }
  let(:core) { instance_double(Stripe::V2::CoreService, accounts: accounts_service) }
  let(:v2) { instance_double(Stripe::V2Services, core: core) }
  let(:stripe_client) { instance_double(Stripe::StripeClient, v2: v2) }

  before { allow(StripeClient).to receive(:instance).and_return(stripe_client) }

  def account(transfer_status:, id: "acct_1")
    double(
      id: id,
      configuration: double(
        recipient: double(
          capabilities: double(
            stripe_balance: double(stripe_transfers: double(status: transfer_status))
          )
        )
      )
    )
  end

  it "promotes a band whose transfers Stripe has activated" do
    band = create(:band, stripe_connect_status: :onboarding, stripe_connect_account_id: "acct_1")
    allow(accounts_service).to receive(:retrieve).and_return(account(transfer_status: "active"))

    described_class.call(band)

    expect(band.reload).to be_stripe_connect_active
  end

  it "records a restriction Stripe has applied" do
    band = create(:band, stripe_connect_status: :active, stripe_connect_account_id: "acct_1")
    allow(accounts_service).to receive(:retrieve).and_return(account(transfer_status: "restricted"))

    described_class.call(band)

    expect(band.reload).to be_stripe_connect_restricted
  end

  it "leaves a band still pending on Stripe as onboarding" do
    band = create(:band, stripe_connect_status: :onboarding, stripe_connect_account_id: "acct_1")
    allow(accounts_service).to receive(:retrieve).and_return(account(transfer_status: "pending"))

    described_class.call(band)

    expect(band.reload).to be_stripe_connect_onboarding
  end

  # v2 omits configuration unless each part is named in `include`. Asking
  # without it returns an account whose capability path reads nil, which
  # would look like "not started" no matter what Stripe had approved — the
  # silent failure this class exists to prevent.
  it "asks Stripe for the configuration it needs to read" do
    band = create(:band, stripe_connect_status: :onboarding, stripe_connect_account_id: "acct_1")
    allow(accounts_service).to receive(:retrieve).and_return(account(transfer_status: "active"))

    described_class.call(band)

    expect(accounts_service).to have_received(:retrieve).with(
      "acct_1",
      include: array_including("configuration.recipient")
    )
  end

  it "does nothing for a band that has no connected account" do
    band = create(:band, stripe_connect_status: :not_started, stripe_connect_account_id: nil)
    allow(accounts_service).to receive(:retrieve)

    described_class.call(band)

    expect(accounts_service).not_to have_received(:retrieve)
    expect(band.reload).to be_stripe_connect_not_started
  end

  it "wraps a Stripe failure rather than leaking it to the caller" do
    band = create(:band, stripe_connect_status: :onboarding, stripe_connect_account_id: "acct_1")
    allow(accounts_service).to receive(:retrieve).and_raise(Stripe::APIConnectionError.new("network down"))

    expect { described_class.call(band) }.to raise_error(described_class::Error, /Could not read/)
  end
end
