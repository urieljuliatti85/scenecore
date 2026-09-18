require "rails_helper"

RSpec.describe StripeConnectedAccountFinancials do
  let(:balance_service) { instance_double(Stripe::BalanceService) }
  let(:payouts_service) { instance_double(Stripe::PayoutService) }
  let(:v1) { instance_double(Stripe::V1Services, balance: balance_service, payouts: payouts_service) }
  let(:stripe_client) { instance_double(Stripe::StripeClient, v1: v1) }
  let(:band) { create(:band, stripe_connect_status: :active, stripe_connect_account_id: "acct_band") }

  def amount(currency, cents)
    double(currency: currency, amount: cents)
  end

  def payout(currency:, cents:, arrival_date:)
    double(currency: currency, amount: cents, arrival_date: arrival_date)
  end

  before do
    allow(StripeClient).to receive(:instance).and_return(stripe_client)
    allow(balance_service).to receive(:retrieve).and_return(
      double(available: [ amount("usd", 7_000), amount("usd", 500) ],
             pending: [ amount("usd", 2_500), amount("eur", 1_200) ])
    )
    allow(payouts_service).to receive(:list).and_return(double(data: []))
  end

  it "reads balance and payouts as the connected account" do
    described_class.call(band)

    options = { stripe_account: "acct_band" }
    expect(balance_service).to have_received(:retrieve).with({}, options)
    expect(payouts_service).to have_received(:list).with({ status: "pending", limit: 100 }, options)
  end

  it "combines amounts by currency without mixing available and pending funds" do
    summary = described_class.call(band)

    expect(summary.balances).to contain_exactly(
      described_class::Balance.new(currency: "eur", available_cents: 0, pending_cents: 1_200),
      described_class::Balance.new(currency: "usd", available_cents: 7_500, pending_cents: 2_500)
    )
  end

  it "chooses the pending payout with the earliest arrival" do
    later = 5.days.from_now.to_i
    sooner = 2.days.from_now.to_i
    allow(payouts_service).to receive(:list).and_return(
      double(data: [
        payout(currency: "usd", cents: 5_000, arrival_date: later),
        payout(currency: "usd", cents: 3_000, arrival_date: sooner)
      ])
    )

    summary = described_class.call(band)

    expect(summary.next_payout.amount_cents).to eq(3_000)
    expect(summary.next_payout.arrival_at.to_i).to eq(sooner)
  end

  it "returns no next payout when Stripe has none pending" do
    expect(described_class.call(band).next_payout).to be_nil
  end

  it "refuses to read financials for an inactive connected account" do
    band.update!(stripe_connect_status: :onboarding)

    expect { described_class.call(band) }.to raise_error(described_class::Error, /active Stripe account/)
    expect(balance_service).not_to have_received(:retrieve)
  end

  it "wraps Stripe failures" do
    allow(balance_service).to receive(:retrieve).and_raise(Stripe::APIConnectionError.new("down"))

    expect { described_class.call(band) }.to raise_error(described_class::Error, /Could not read/)
  end
end
