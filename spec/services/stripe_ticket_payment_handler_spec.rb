require "rails_helper"

RSpec.describe StripeTicketPaymentHandler do
  let(:order) { create(:ticket_order, quantity: 2, stripe_checkout_session_id: "cs_ticket_1") }

  def session(payment_status: "paid")
    instance_double(Stripe::Checkout::Session, id: "cs_ticket_1", payment_status: payment_status,
                                              payment_intent: "pi_ticket_1")
  end

  it "marks the order paid and issues one opaque ticket per seat" do
    order

    expect { described_class.call(session) }.to change(Ticket, :count).by(2)

    expect(order.reload).to be_paid
    expect(order.stripe_payment_intent_id).to eq("pi_ticket_1")
    expect(order.tickets.pluck(:public_token).uniq.length).to eq(2)
  end

  it "is idempotent for a repeated completion" do
    order
    described_class.call(session)

    expect { described_class.call(session) }.not_to change(Ticket, :count)
  end

  it "ignores unpaid sessions" do
    order

    expect { described_class.call(session(payment_status: "unpaid")) }.not_to change(Ticket, :count)
    expect(order.reload).to be_pending
  end

  it "uses signed checkout metadata when the completion races the local session-id write" do
    order = create(:ticket_order)
    raced_session = instance_double(
      Stripe::Checkout::Session,
      id: "cs_ticket_race",
      payment_status: "paid",
      payment_intent: "pi_ticket_race",
      metadata: { "ticket_order_id" => order.id.to_s }
    )

    described_class.call(raced_session)

    expect(order.reload).to be_paid
    expect(order.stripe_checkout_session_id).to eq("cs_ticket_race")
    expect(order.tickets.count).to eq(1)
  end
end
