require "rails_helper"

RSpec.describe StoreOrderRefundCreator do
  let(:refunds_service) { instance_double(Stripe::RefundService) }
  let(:sessions_service) { instance_double(Stripe::Checkout::SessionService) }
  let(:checkout_service) { instance_double(Stripe::CheckoutService, sessions: sessions_service) }
  let(:v1) { instance_double(Stripe::V1Services, refunds: refunds_service, checkout: checkout_service) }
  let(:stripe_client) { instance_double(Stripe::StripeClient, v1: v1) }
  let(:refund) { instance_double(Stripe::Refund, id: "re_1", status: "pending") }
  let(:order) do
    create(:order, :paid, stripe_checkout_session_id: "cs_1",
                          stripe_payment_intent_id: "pi_1")
  end

  before do
    allow(StripeClient).to receive(:instance).and_return(stripe_client)
    allow(refunds_service).to receive(:create).and_return(refund)
  end

  it "requests a full refund with transfer and application fee reversal" do
    described_class.call(order)

    expect(refunds_service).to have_received(:create).with(
      {
        payment_intent: "pi_1",
        reverse_transfer: true,
        refund_application_fee: true,
        reason: "requested_by_customer",
        metadata: { order_id: order.id, band_id: order.band_id }
      },
      { idempotency_key: "store-order-refund-#{order.id}" }
    )
  end

  it "records the request but waits for the webhook to mark the order refunded" do
    described_class.call(order)

    order.reload
    expect(order).to be_paid
    expect(order.stripe_refund_id).to eq("re_1")
    expect(order.refund_status).to eq("pending")
    expect(order.refunded_at).to be_nil
  end

  it "retrieves the PaymentIntent for an order paid before it was stored locally" do
    order.update!(stripe_payment_intent_id: nil)
    session = instance_double(Stripe::Checkout::Session, payment_intent: "pi_legacy")
    allow(sessions_service).to receive(:retrieve).with("cs_1").and_return(session)

    described_class.call(order)

    expect(order.reload.stripe_payment_intent_id).to eq("pi_legacy")
    expect(refunds_service).to have_received(:create)
      .with(hash_including(payment_intent: "pi_legacy"), anything)
  end

  it "refuses an order that is not refundable" do
    order.update!(status: :pending)

    expect { described_class.call(order) }
      .to raise_error(described_class::Error, /can't be refunded/)
    expect(refunds_service).not_to have_received(:create)
  end

  it "prevents a second refund request" do
    described_class.call(order)

    expect { described_class.call(order.reload) }
      .to raise_error(described_class::Error, /can't be refunded/)
    expect(refunds_service).to have_received(:create).once
  end

  it "wraps Stripe errors without recording a refund" do
    allow(refunds_service).to receive(:create)
      .and_raise(Stripe::InvalidRequestError.new("refund unavailable", "payment_intent"))

    expect { described_class.call(order) }
      .to raise_error(described_class::Error, /Stripe could not start/)
    expect(order.reload.stripe_refund_id).to be_nil
  end
end
