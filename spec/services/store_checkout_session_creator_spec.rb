require "rails_helper"

RSpec.describe StoreCheckoutSessionCreator do
  let(:sessions_service) { instance_double(Stripe::Checkout::SessionService) }
  let(:checkout) { instance_double(Stripe::CheckoutService, sessions: sessions_service) }
  let(:v1) { instance_double(Stripe::V1Services, checkout: checkout) }
  let(:stripe_client) { instance_double(Stripe::StripeClient, v1: v1) }
  let(:session) { instance_double(Stripe::Checkout::Session, id: "cs_store_1", url: "https://checkout.stripe.com/pay/cs_store_1") }

  let(:band) do
    create(:band, :approved, name: "The Testers",
           stripe_connect_status: :active, stripe_connect_account_id: "acct_1")
  end
  let(:order) do
    order = create(:user).orders.create!(
      band: band, subtotal_cents: 12_000, shipping_cents: 1_500,
      total_cents: 13_500, platform_fee_cents: 1_200
    )
    order.order_items.create!(product_name: "Vinyl", variant_name: "Standard",
                              unit_price_cents: 12_000, quantity: 1)
    order
  end

  before { allow(StripeClient).to receive(:instance).and_return(stripe_client) }

  def create_session
    described_class.call(order, success_url: "https://example.com/ok", cancel_url: "https://example.com/cancel")
  end

  it "returns the session url and records the session id on the order" do
    allow(sessions_service).to receive(:create).and_return(session)

    expect(create_session).to eq("https://checkout.stripe.com/pay/cs_store_1")
    expect(order.reload.stripe_checkout_session_id).to eq("cs_store_1")
  end

  # ADR-007: the band's connected account receives the payment and SceneCore
  # takes its commission in the same transaction, rather than collecting the
  # full amount and paying the band out separately.
  it "splits the payment to the band's connected account" do
    allow(sessions_service).to receive(:create).and_return(session)

    create_session

    expect(sessions_service).to have_received(:create).with(
      hash_including(
        mode: "payment",
        payment_intent_data: {
          application_fee_amount: 1_200,
          transfer_data: { destination: "acct_1" }
        }
      )
    )
  end

  it "charges the amounts snapshotted on the order, not the live product" do
    allow(sessions_service).to receive(:create).and_return(session)

    create_session

    expect(sessions_service).to have_received(:create) do |args|
      product_line = args[:line_items].find { |i| i[:price_data][:product_data][:name].include?("Vinyl") }

      expect(product_line[:price_data][:unit_amount]).to eq(12_000)
      expect(product_line[:quantity]).to eq(1)
    end
  end

  it "bills shipping as its own line when the order charges for it" do
    allow(sessions_service).to receive(:create).and_return(session)

    create_session

    expect(sessions_service).to have_received(:create) do |args|
      shipping = args[:line_items].find { |i| i[:price_data][:product_data][:name] == "Shipping" }

      expect(shipping[:price_data][:unit_amount]).to eq(1_500)
    end
  end

  it "omits the shipping line when shipping is free" do
    order.update!(shipping_cents: 0, total_cents: 12_000)
    allow(sessions_service).to receive(:create).and_return(session)

    create_session

    expect(sessions_service).to have_received(:create) do |args|
      expect(args[:line_items].map { |i| i[:price_data][:product_data][:name] }).not_to include("Shipping")
    end
  end

  describe "when the band cannot take payments" do
    it "refuses a band that has not finished onboarding" do
      band.update!(stripe_connect_status: :onboarding)

      expect { create_session }.to raise_error(described_class::Error, /can't take payments/)
    end

    it "refuses a band whose account Stripe has restricted" do
      band.update!(stripe_connect_status: :restricted)

      expect { create_session }.to raise_error(described_class::Error, /can't take payments/)
    end

    it "refuses a band with an active status but no account id" do
      band.update_columns(stripe_connect_account_id: nil)

      expect { create_session }.to raise_error(described_class::Error, /can't take payments/)
    end
  end

  it "wraps a Stripe failure rather than leaking it to the controller" do
    allow(sessions_service).to receive(:create).and_raise(Stripe::InvalidRequestError.new("no such account", "account"))

    expect { create_session }.to raise_error(described_class::Error, /Could not start checkout/)
  end
end
