require "rails_helper"

RSpec.describe Order do
  describe "validations" do
    it "defaults to pending" do
      expect(described_class.new).to be_pending
    end

    it "rejects negative amounts" do
      expect(build(:order, subtotal_cents: -1)).not_to be_valid
      expect(build(:order, total_cents: -1)).not_to be_valid
      expect(build(:order, platform_fee_cents: -1)).not_to be_valid
      expect(build(:order, shipping_cents: -1)).not_to be_valid
    end
  end

  describe "associations" do
    it "destroys its items and shipping address when destroyed" do
      order = create(:order)
      create(:order_item, order: order)
      create(:shipping_address, order: order)

      order.destroy!

      expect(OrderItem.count).to eq(0)
      expect(ShippingAddress.count).to eq(0)
    end

    it "holds at most one shipping address" do
      order = create(:order)
      create(:shipping_address, order: order)

      expect { create(:shipping_address, order: order) }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe "fulfilment" do
    # A band only ever moves an order forward. pending belongs to Stripe,
    # and cancelled/refunded move money back — that needs the refund policy
    # docs/product.md §7 still leaves open.
    it "advances a paid order to processing" do
      order = create(:order, :paid)

      order.advance_fulfilment!

      expect(order.reload).to be_processing
    end

    it "advances a processing order to completed" do
      order = create(:order, status: :processing)

      order.advance_fulfilment!

      expect(order.reload).to be_completed
    end

    it "refuses to advance a pending order, which Stripe has not confirmed" do
      order = create(:order, status: :pending)

      expect(order.next_fulfilment_status).to be_nil
      expect { order.advance_fulfilment! }.to raise_error(ArgumentError)
    end

    it "refuses to advance past completed" do
      order = create(:order, status: :completed)

      expect(order.next_fulfilment_status).to be_nil
      expect { order.advance_fulfilment! }.to raise_error(ArgumentError)
    end

    it "offers no fulfilment step for a refunded or cancelled order" do
      expect(create(:order, status: :refunded).next_fulfilment_status).to be_nil
      expect(create(:order, status: :cancelled).next_fulfilment_status).to be_nil
    end
  end

  describe ".awaiting_band" do
    # These are the orders the band owes goods on: money arrived, nothing
    # shipped yet.
    it "includes paid and processing orders, oldest first" do
      older = create(:order, :paid, created_at: 2.days.ago)
      newer = create(:order, status: :processing, created_at: 1.day.ago)

      expect(described_class.awaiting_band).to eq([ older, newer ])
    end

    it "excludes a pending order, which is still Stripe's to confirm" do
      create(:order, status: :pending)

      expect(described_class.awaiting_band).to be_empty
    end

    it "excludes orders already finished or reversed" do
      create(:order, status: :completed)
      create(:order, status: :cancelled)
      create(:order, status: :refunded)

      expect(described_class.awaiting_band).to be_empty
    end
  end
end
