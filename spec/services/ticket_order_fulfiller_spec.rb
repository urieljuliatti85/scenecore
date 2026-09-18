require "rails_helper"

RSpec.describe TicketOrderFulfiller do
  it "issues free tickets without a Stripe payment" do
    batch = create(:ticket_batch, price_cents: 0)
    order = create(:ticket_order, ticket_batch: batch, quantity: 2,
                                  unit_price_cents: 0, total_cents: 0,
                                  platform_fee_cents: 0)

    expect { described_class.call(order) }.to change(Ticket, :count).by(2)
    expect(order.reload).to be_paid
    expect(order.stripe_payment_intent_id).to be_nil
  end
end
