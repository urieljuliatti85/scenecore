require "rails_helper"

RSpec.describe OrderItem do
  describe "price/name snapshot" do
    it "keeps its recorded values when the live variant changes afterwards" do
      variant = create(:product_variant, name: "Size M", price_cents: 2_500)
      item = create(:order_item, product_variant: variant, product_name: "Tour Tee",
                                 variant_name: "Size M", unit_price_cents: 2_500)

      variant.update!(name: "Size L", price_cents: 9_900)

      expect(item.reload.variant_name).to eq("Size M")
      expect(item.unit_price_cents).to eq(2_500)
      expect(item.product_name).to eq("Tour Tee")
    end

    it "survives deletion of the variant it referenced" do
      variant = create(:product_variant)
      item = create(:order_item, product_variant: variant)

      variant.destroy!

      expect(item.reload.product_variant_id).to be_nil
      expect(item.unit_price_cents).to be_present
    end
  end

  describe "validations" do
    it "requires the snapshot names" do
      expect(build(:order_item, product_name: nil)).not_to be_valid
      expect(build(:order_item, variant_name: nil)).not_to be_valid
    end

    it "rejects a non-positive quantity" do
      expect(build(:order_item, quantity: 0)).not_to be_valid
    end
  end
end
