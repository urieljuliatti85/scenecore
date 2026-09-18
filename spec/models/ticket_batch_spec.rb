require "rails_helper"

RSpec.describe TicketBatch, type: :model do
  it "counts paid tickets and live reservations against availability" do
    batch = create(:ticket_batch, quantity_total: 6)
    create(:ticket_order, :paid, ticket_batch: batch, quantity: 2,
                                unit_price_cents: batch.price_cents,
                                total_cents: batch.price_cents * 2)
    create(:ticket_order, ticket_batch: batch, quantity: 3,
                          unit_price_cents: batch.price_cents,
                          total_cents: batch.price_cents * 3,
                          expires_at: 10.minutes.from_now)

    expect(batch.remaining_quantity).to eq(1)
  end

  it "releases expired reservations" do
    batch = create(:ticket_batch, quantity_total: 2)
    create(:ticket_order, ticket_batch: batch, quantity: 2,
                          unit_price_cents: batch.price_cents,
                          total_cents: batch.price_cents * 2,
                          expires_at: 1.minute.ago)

    expect(batch.remaining_quantity).to eq(2)
  end

  it "is not on sale before its sales window" do
    batch = create(:ticket_batch, sales_start_at: 1.hour.from_now)

    expect(batch).not_to be_on_sale
  end

  it "cannot shrink below sold and currently reserved tickets" do
    batch = create(:ticket_batch, quantity_total: 5)
    create(:ticket_order, :paid, ticket_batch: batch, quantity: 3,
                                unit_price_cents: batch.price_cents,
                                total_cents: batch.price_cents * 3)

    expect(batch.update(quantity_total: 2)).to be(false)
    expect(batch.errors[:quantity_total]).to include("cannot be lower than 3 sold or reserved tickets")
  end
end
