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
end
