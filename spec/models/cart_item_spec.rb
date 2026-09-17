require "rails_helper"

RSpec.describe CartItem do
  describe "single-band cart (ADR-003)" do
    it "rejects a variant belonging to a different band than the cart" do
      cart = create(:cart)
      other_variant = create(:product_variant, product: create(:product, band: create(:band)))

      item = build(:cart_item, cart: cart, product_variant: other_variant)

      expect(item).not_to be_valid
      expect(item.errors[:product_variant]).to include("must belong to the cart's band")
    end

    it "accepts a variant from the cart's own band" do
      cart = create(:cart)
      variant = create(:product_variant, product: create(:product, band: cart.band))

      expect(build(:cart_item, cart: cart, product_variant: variant)).to be_valid
    end
  end

  describe "validations" do
    it "rejects a non-positive quantity" do
      expect(build(:cart_item, quantity: 0)).not_to be_valid
    end

    it "does not allow the same variant twice in one cart" do
      existing = create(:cart_item)
      duplicate = build(:cart_item, cart: existing.cart, product_variant: existing.product_variant)

      expect(duplicate).not_to be_valid
    end
  end
end
