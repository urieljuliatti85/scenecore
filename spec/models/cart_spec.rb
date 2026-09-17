require "rails_helper"

RSpec.describe Cart do
  describe "one active cart per user" do
    it "prevents a second active cart for the same user, even for another band" do
      user = create(:user)
      create(:cart, user: user, band: create(:band))

      expect { create(:cart, user: user, band: create(:band)) }
        .to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "allows a new active cart once the previous one is converted" do
      user = create(:user)
      create(:cart, :converted, user: user)

      expect { create(:cart, user: user) }.not_to raise_error
    end

    it "allows different users to each hold an active cart" do
      create(:cart, user: create(:user))

      expect { create(:cart, user: create(:user)) }.not_to raise_error
    end
  end

  describe "#subtotal_cents" do
    it "sums quantity times unit price across items" do
      cart = create(:cart)
      product = create(:product, band: cart.band)
      create(:cart_item, cart: cart, quantity: 2,
                         product_variant: create(:product_variant, product: product, price_cents: 1_000))
      create(:cart_item, cart: cart, quantity: 1,
                         product_variant: create(:product_variant, product: product, price_cents: 500))

      expect(cart.subtotal_cents).to eq(2_500)
    end

    it "is zero for an empty cart" do
      expect(create(:cart).subtotal_cents).to eq(0)
    end
  end
end
