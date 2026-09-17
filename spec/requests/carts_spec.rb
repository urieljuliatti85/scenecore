require "rails_helper"

RSpec.describe "Carts", type: :request do
  let(:user) { create(:user) }
  let(:band) { create(:band, :approved, name: "The Testers") }
  let(:product) { create(:product, :published, band: band, name: "Vinyl", shipping_cents: 1_500) }
  let!(:variant) { product.variants.create!(name: "Standard", sku: "V-1", price_cents: 12_000, stock_quantity: 5) }

  describe "authentication" do
    it "requires signing in to see a cart" do
      get cart_path

      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "POST /cart/add" do
    before { sign_in user }

    it "adds a variant to a new cart" do
      expect { post add_cart_path, params: { product_variant_id: variant.id } }
        .to change(Cart, :count).by(1)

      expect(user.carts.sole.cart_items.sole.quantity).to eq(1)
    end

    # A new cart_item carries the column default of 1, so the first add must
    # not count that unit and then add another on top of it.
    it "adds one unit when no quantity is given" do
      post add_cart_path, params: { product_variant_id: variant.id }

      expect(user.carts.sole.cart_items.sole.quantity).to eq(1)
    end

    it "accumulates when the same variant is added again" do
      post add_cart_path, params: { product_variant_id: variant.id, quantity: 2 }
      post add_cart_path, params: { product_variant_id: variant.id, quantity: 1 }

      expect(user.carts.sole.cart_items.sole.quantity).to eq(3)
    end

    it "refuses more than the variant has in stock" do
      post add_cart_path, params: { product_variant_id: variant.id, quantity: 99 }

      expect(flash[:alert]).to include("Only 5 left")
      expect(user.carts.sole.cart_items).to be_empty
    end

    it "refuses a draft product" do
      draft = create(:product, band: band)
      draft_variant = draft.variants.create!(name: "Hidden", sku: "H-1", price_cents: 100, stock_quantity: 1)

      post add_cart_path, params: { product_variant_id: draft_variant.id }

      expect(flash[:alert]).to include("isn't available")
      expect(Cart.count).to be_zero
    end
  end

  # A cart holds one band's products at a time (ADR-003). The fan confirms
  # the switch rather than losing the current cart without being asked.
  describe "adding another band's product" do
    let(:other_band) { create(:band, :approved, name: "Other Band") }
    let(:other_product) { create(:product, :published, band: other_band) }
    let!(:other_variant) { other_product.variants.create!(name: "Tee", sku: "T-1", price_cents: 2_500, stock_quantity: 2) }

    before do
      sign_in user
      post add_cart_path, params: { product_variant_id: variant.id }
    end

    it "keeps the current cart and asks first" do
      post add_cart_path, params: { product_variant_id: other_variant.id }

      cart = user.carts.find_by(status: :active)

      expect(cart.band).to eq(band)
      expect(cart.cart_items.count).to eq(1)
      expect(flash[:alert]).to include("The Testers")
    end

    it "replaces the cart once the switch is confirmed" do
      post add_cart_path, params: { product_variant_id: other_variant.id, confirm_switch: "1" }

      cart = user.carts.find_by(status: :active)

      expect(cart.band).to eq(other_band)
      expect(cart.cart_items.sole.product_variant).to eq(other_variant)
    end

    it "leaves only one active cart after a switch" do
      post add_cart_path, params: { product_variant_id: other_variant.id, confirm_switch: "1" }

      expect(user.carts.where(status: :active).count).to eq(1)
    end
  end

  describe "PATCH /cart/update_item" do
    before do
      sign_in user
      post add_cart_path, params: { product_variant_id: variant.id }
    end

    it "changes the quantity" do
      item = user.carts.sole.cart_items.sole

      patch update_item_cart_path, params: { cart_item_id: item.id, quantity: 3 }

      expect(item.reload.quantity).to eq(3)
    end

    it "removes the item when the quantity is set to zero" do
      item = user.carts.sole.cart_items.sole

      patch update_item_cart_path, params: { cart_item_id: item.id, quantity: 0 }

      expect(CartItem.exists?(item.id)).to be false
    end

    it "refuses more than the variant has in stock" do
      item = user.carts.sole.cart_items.sole

      patch update_item_cart_path, params: { cart_item_id: item.id, quantity: 50 }

      expect(item.reload.quantity).to eq(1)
      expect(flash[:alert]).to include("Only 5 left")
    end

    # The quantity comes from a form field, and the cart_items check
    # constraint rejects anything below 1 — a negative must not reach it.
    it "treats a negative quantity as removal rather than raising" do
      item = user.carts.sole.cart_items.sole

      patch update_item_cart_path, params: { cart_item_id: item.id, quantity: -5 }

      expect(response).to have_http_status(:found)
      expect(CartItem.exists?(item.id)).to be false
    end

    it "does not let a fan touch another fan's cart item" do
      other_user = create(:user)
      other_cart = other_user.carts.create!(band: band)
      other_item = other_cart.cart_items.create!(product_variant: variant, quantity: 1)

      patch update_item_cart_path, params: { cart_item_id: other_item.id, quantity: 9 }

      expect(other_item.reload.quantity).to eq(1)
    end
  end

  describe "totals" do
    before { sign_in user }

    # Shipping is per product, not per unit: two copies ship together.
    it "charges shipping once however many units are bought" do
      post add_cart_path, params: { product_variant_id: variant.id, quantity: 3 }

      cart = user.carts.sole

      expect(cart.subtotal_cents).to eq(36_000)
      expect(cart.shipping_cents).to eq(1_500)
      expect(cart.total_cents).to eq(37_500)
    end

    it "sums shipping across distinct products" do
      second = create(:product, :published, band: band, shipping_cents: 500)
      second_variant = second.variants.create!(name: "Tee", sku: "T-2", price_cents: 2_000, stock_quantity: 2)

      post add_cart_path, params: { product_variant_id: variant.id }
      post add_cart_path, params: { product_variant_id: second_variant.id }

      expect(user.carts.sole.shipping_cents).to eq(2_000)
    end

    it "shows free shipping when no product charges for it" do
      free = create(:product, :published, band: band, shipping_cents: 0)
      free_variant = free.variants.create!(name: "Digital", sku: "D-1", price_cents: 1_000, stock_quantity: 1)

      post add_cart_path, params: { product_variant_id: free_variant.id }
      get cart_path

      expect(response.body).to include("Free")
    end
  end

  describe "DELETE /cart" do
    it "empties the cart" do
      sign_in user
      post add_cart_path, params: { product_variant_id: variant.id }

      delete cart_path

      expect(user.carts.where(status: :active)).to be_empty
    end
  end
end
