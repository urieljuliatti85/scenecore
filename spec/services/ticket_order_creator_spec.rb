require "rails_helper"

RSpec.describe TicketOrderCreator do
  let(:user) { create(:user) }
  let(:batch) { create(:ticket_batch, quantity_total: 3, price_cents: 2_000) }

  it "reserves the requested quantity and snapshots the price" do
    order = described_class.call(user: user, ticket_batch: batch, quantity: 2)

    expect(order).to be_pending
    expect(order.quantity).to eq(2)
    expect(order.total_cents).to eq(4_000)
    expect(order.platform_fee_cents).to eq(400)
    expect(batch.remaining_quantity).to eq(1)
  end

  it "refuses to oversell the batch" do
    described_class.call(user: user, ticket_batch: batch, quantity: 2)

    expect {
      described_class.call(user: create(:user), ticket_batch: batch, quantity: 2)
    }.to raise_error(described_class::Error, "Only 1 tickets remain.")
  end

  it "limits one checkout to ten tickets" do
    expect {
      described_class.call(user: user, ticket_batch: batch, quantity: 11)
    }.to raise_error(described_class::Error, /between 1 and 10/)
  end
end
