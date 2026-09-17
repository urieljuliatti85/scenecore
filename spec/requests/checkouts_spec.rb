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
    let(:sessions_service) { instance_double(Stripe::Checkout::SessionService) }
    let(:checkout) { instance_double(Stripe::CheckoutService, sessions: sessions_service) }
    let(:v1) { instance_double(Stripe::V1Services, checkout: checkout) }
    let(:stripe_client) { instance_double(Stripe::StripeClient, v1: v1) }
    let(:stripe_session) do
      instance_double(Stripe::Checkout::Session, id: "cs_store_1", url: "https://checkout.stripe.com/pay/cs_store_1")
    end

    before do
      band.update!(stripe_connect_status: :active, stripe_connect_account_id: "acct_1")
      allow(StripeClient).to receive(:instance).and_return(stripe_client)
      allow(sessions_service).to receive(:create).and_return(stripe_session)
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

    # Stock moves when the webhook confirms payment, not when the fan is
    # handed to Stripe — an abandoned checkout must not consume inventory.
    it "does not decrement stock before payment is confirmed" do
      expect { post checkout_path, params: { shipping_address: address_params } }
        .not_to change { variant.reload.stock_quantity }
    end

    it "hands the fan to Stripe" do
      post checkout_path, params: { shipping_address: address_params }

      expect(response).to redirect_to("https://checkout.stripe.com/pay/cs_store_1")
    end

    it "records the session id so the webhook can find the order" do
      post checkout_path, params: { shipping_address: address_params }

      expect(Order.last.stripe_checkout_session_id).to eq("cs_store_1")
    end
  end

  describe "POST /checkout when the band cannot take payments" do
    before do
      sign_in user
      add_to_cart
    end

    # A band still onboarding can hold a Connect id without Stripe having
    # cleared it, so the fan is stopped before an order exists rather than
    # being sent to a session that cannot be paid.
    it "refuses and creates no order" do
      band.update!(stripe_connect_status: :onboarding, stripe_connect_account_id: "acct_1")

      expect { post checkout_path, params: { shipping_address: address_params } }
        .not_to change(Order, :count)

      expect(response).to redirect_to(cart_path)
      expect(flash[:alert]).to include("can't take payments")
    end

    it "leaves the cart intact so the fan does not lose it" do
      band.update!(stripe_connect_status: :not_started)

      post checkout_path, params: { shipping_address: address_params }

      expect(user.carts.sole).to be_active
    end

    # If Stripe rejects the session the order would otherwise be stranded:
    # unpayable, with no cart left to retry from.
    it "discards the order and keeps the cart when Stripe fails" do
      band.update!(stripe_connect_status: :active, stripe_connect_account_id: "acct_1")
      allow(StripeClient).to receive(:instance).and_return(
        instance_double(Stripe::StripeClient, v1: instance_double(Stripe::V1Services,
          checkout: instance_double(Stripe::CheckoutService,
            sessions: instance_double(Stripe::Checkout::SessionService))))
      )
      allow(StripeClient.instance.v1.checkout.sessions).to receive(:create)
        .and_raise(Stripe::InvalidRequestError.new("no such account", "account"))

      expect { post checkout_path, params: { shipping_address: address_params } }
        .not_to change(Order, :count)

      expect(user.carts.sole).to be_active
      expect(flash[:alert]).to include("Could not start checkout")
    end
  end
end
