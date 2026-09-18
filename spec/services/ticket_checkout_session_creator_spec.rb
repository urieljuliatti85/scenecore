require "rails_helper"

RSpec.describe TicketCheckoutSessionCreator do
  let(:sessions_service) { instance_double(Stripe::Checkout::SessionService) }
  let(:checkout) { instance_double(Stripe::CheckoutService, sessions: sessions_service) }
  let(:v1) { instance_double(Stripe::V1Services, checkout: checkout) }
  let(:stripe_client) { instance_double(Stripe::StripeClient, v1: v1) }
  let(:session) { instance_double(Stripe::Checkout::Session, id: "cs_ticket_1", url: "https://checkout.stripe.com/pay/cs_ticket_1") }
  let(:band) { create(:band, :approved, :payouts_ready) }
  let(:event) { create(:event, :published, band: band, title: "SceneCore Fest") }
  let(:batch) { create(:ticket_batch, event: event, name: "First release", price_cents: 3_000) }
  let(:order) do
    create(:ticket_order, ticket_batch: batch, quantity: 2, unit_price_cents: 3_000,
                          total_cents: 6_000, platform_fee_cents: 600)
  end

  before { allow(StripeClient).to receive(:instance).and_return(stripe_client) }

  it "creates a destination charge from the snapshotted order" do
    allow(sessions_service).to receive(:create).and_return(session)

    url = described_class.call(order, success_url: "https://example.com/ok", cancel_url: "https://example.com/cancel")

    expect(url).to eq(session.url)
    expect(order.reload.stripe_checkout_session_id).to eq("cs_ticket_1")
    expect(sessions_service).to have_received(:create).with(
      hash_including(
        mode: "payment",
        line_items: [ hash_including(quantity: 2, price_data: hash_including(unit_amount: 3_000)) ],
        payment_intent_data: {
          application_fee_amount: 600,
          transfer_data: { destination: band.stripe_connect_account_id }
        },
        expires_at: order.expires_at.to_i
      )
    )
  end

  it "refuses checkout while the band's Stripe account is restricted" do
    band.update!(stripe_connect_status: :restricted)

    expect {
      described_class.call(order, success_url: "https://example.com/ok", cancel_url: "https://example.com/cancel")
    }.to raise_error(described_class::Error, /can't take payments/)
  end
end
