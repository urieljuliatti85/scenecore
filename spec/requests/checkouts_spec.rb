require "rails_helper"

RSpec.describe "Checkouts", type: :request do
  let(:user) { create(:user) }
  let(:band) { create(:band, :approved, name: "The Testers") }
  let(:product) { create(:product, :published, band: band, name: "Vinyl", shipping_cents: 1_500) }
  let!(:variant) { product.variants.create!(name: "Standard", sku: "V-1", price_cents: 12_000, stock_quantity: 5) }

  let(:address_params) do
    {
      recipient_name: "Bob Tester", line1: "1 Main St", city: "Springfield",
      state: "IL", postal_code: "62704", country: "US"
    }
  end

  def add_to_cart(quantity: 1)
    post add_cart_path, params: { product_variant_id: variant.id, quantity: quantity }
  end

  describe "GET /checkout/new" do
    it "requires signing in" do
      get new_checkout_path

      expect(response).to redirect_to(new_user_session_path)
    end

    it "sends a fan with an empty cart back to the cart" do
      sign_in user

      get new_checkout_path

      expect(response).to redirect_to(cart_path)
    end

    it "shows the order summary" do
      sign_in user
      add_to_cart(quantity: 2)

      get new_checkout_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("$240.00")
      expect(response.body).to include("$255.00")
    end
  end

  describe "POST /checkout" do
    before do
      sign_in user
      add_to_cart
    end

    it "creates a pending order with its address" do
      expect { post checkout_path, params: { shipping_address: address_params } }
        .to change(Order, :count).by(1)
        .and change(ShippingAddress, :count).by(1)

      order = Order.last

      expect(order).to be_pending
      expect(order.user).to eq(user)
      expect(order.band).to eq(band)
      expect(order.shipping_address.city).to eq("Springfield")
    end

    it "converts the cart so it is no longer active" do
      post checkout_path, params: { shipping_address: address_params }

      expect(user.carts.where(status: :active)).to be_empty
      expect(user.carts.sole).to be_converted
    end

    # docs/database.md Orders: the commission is 10% of the subtotal. Taking
    # it on the total would have SceneCore keeping a slice of the shipping
    # the band pays out to post the goods.
    it "takes the platform fee from the subtotal, not the total" do
      post checkout_path, params: { shipping_address: address_params }

      order = Order.last

      expect(order.subtotal_cents).to eq(12_000)
      expect(order.shipping_cents).to eq(1_500)
      expect(order.total_cents).to eq(13_500)
      expect(order.platform_fee_cents).to eq(1_200)
    end

    # docs/database.md OrderItems: the line is frozen at purchase time, so a
    # later price edit cannot rewrite what someone agreed to pay.
    it "snapshots the product name and price onto the order item" do
      post checkout_path, params: { shipping_address: address_params }

      item = Order.last.order_items.sole
      variant.update!(price_cents: 99_999, name: "Renamed")

      expect(item.product_name).to eq("Vinyl")
      expect(item.variant_name).to eq("Standard")
      expect(item.unit_price_cents).to eq(12_000)
    end

    it "re-renders and creates nothing when the address is incomplete" do
      expect {
        post checkout_path, params: { shipping_address: address_params.merge(city: "") }
      }.not_to change(Order, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(user.carts.sole).to be_active
    end

    # Payment is not wired yet (roadmap 8.1 step 6). Stock must not be
    # consumed before a charge succeeds, or a failed payment would leave
    # inventory sold that nobody paid for.
    it "does not decrement stock yet" do
      expect { post checkout_path, params: { shipping_address: address_params } }
        .not_to change { variant.reload.stock_quantity }
    end
  end
end
