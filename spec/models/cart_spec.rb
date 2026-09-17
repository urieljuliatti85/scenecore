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

  describe "shipping by destination" do
    let(:band) { create(:band, :approved) }
    let(:cart) { create(:cart, band: band) }
    let(:heavy) { create(:product, band: band, shipping_cents: 900) }
    let(:light) { create(:product, band: band, shipping_cents: 400) }

    before do
      create(:cart_item, cart: cart, quantity: 2,
                         product_variant: create(:product_variant, product: heavy, price_cents: 1_000))
    end

    context "when the band has no zones" do
      it "falls back to the products' flat rates for any country" do
        expect(cart.shipping_cents_for("JP")).to eq(900)
        expect(cart.total_cents_for("JP")).to eq(2_000 + 900)
      end

      it "reports a single-value range" do
        expect(cart.shipping_cents_range).to eq([ 900, 900 ])
      end
    end

    context "when the band has zones" do
      let!(:domestic) { create(:shipping_zone, band: band, name: "Brazil", shipping_cents: 1_500, country_codes: [ "BR" ]) }
      let!(:abroad) { create(:shipping_zone, band: band, name: "Europe", shipping_cents: 4_000, country_codes: [ "PT" ]) }

      it "charges the destination's rate" do
        expect(cart.shipping_cents_for("BR")).to eq(1_500)
        expect(cart.shipping_cents_for("PT")).to eq(4_000)
      end

      it "charges once per distinct product, not per unit" do
        expect(cart.shipping_cents_for("BR")).to eq(1_500)
      end

      it "sums across distinct products" do
        create(:cart_item, cart: cart, quantity: 1,
                           product_variant: create(:product_variant, product: light, price_cents: 500))

        expect(cart.reload.shipping_cents_for("BR")).to eq(3_000)
      end

      # An order the band cannot ship must not be totalled at a guessed
      # price — nil is what stops the checkout.
      it "refuses a country no zone covers" do
        expect(cart.shipping_cents_for("JP")).to be_nil
        expect(cart.total_cents_for("JP")).to be_nil
      end

      it "refuses when one product in the cart cannot reach the destination" do
        expect(cart.shipping_cents_for("")).to be_nil
      end

      it "spans the cheapest and dearest destination in its range" do
        expect(cart.shipping_cents_range).to eq([ 1_500, 4_000 ])
      end
    end
  end
end
