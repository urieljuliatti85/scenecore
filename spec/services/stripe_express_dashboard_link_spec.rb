require "rails_helper"

RSpec.describe StripeExpressDashboardLink do
  let(:login_links_service) { instance_double(Stripe::AccountLoginLinkService) }
  let(:accounts_service) { instance_double(Stripe::AccountService, login_links: login_links_service) }
  let(:v1) { instance_double(Stripe::V1Services, accounts: accounts_service) }
  let(:stripe_client) { instance_double(Stripe::StripeClient, v1: v1) }
  let(:band) { create(:band, stripe_connect_status: :active, stripe_connect_account_id: "acct_band") }

  before do
    allow(StripeClient).to receive(:instance).and_return(stripe_client)
    allow(login_links_service).to receive(:create)
      .with("acct_band").and_return(double(url: "https://connect.stripe.com/express/test"))
  end

  it "creates a fresh Express Dashboard link for the band's account" do
    expect(described_class.call(band)).to eq("https://connect.stripe.com/express/test")
    expect(login_links_service).to have_received(:create).with("acct_band")
  end

  it "refuses an inactive connected account" do
    band.update!(stripe_connect_status: :restricted)

    expect { described_class.call(band) }.to raise_error(described_class::Error, /active Stripe account/)
    expect(login_links_service).not_to have_received(:create)
  end

  it "wraps Stripe failures" do
    allow(login_links_service).to receive(:create)
      .and_raise(Stripe::APIConnectionError.new("down"))

    expect { described_class.call(band) }.to raise_error(described_class::Error, /Could not open/)
  end
end
