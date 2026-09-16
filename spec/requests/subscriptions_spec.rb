require "rails_helper"

RSpec.describe "Subscriptions", type: :request do
  let(:products_service) { instance_double(Stripe::ProductService) }
  let(:prices_service) { instance_double(Stripe::PriceService) }
  let(:customers_service) { instance_double(Stripe::CustomerService) }
  let(:sessions_service) { instance_double(Stripe::Checkout::SessionService) }
  let(:checkout) { instance_double(Stripe::CheckoutService, sessions: sessions_service) }
  let(:v1) do
    instance_double(Stripe::V1Services, products: products_service, prices: prices_service,
                                         customers: customers_service, checkout: checkout)
  end
  let(:stripe_client) { instance_double(Stripe::StripeClient, v1: v1) }

  before do
    allow(StripeClient).to receive(:instance).and_return(stripe_client)
  end

  describe "POST /bands/:band_id/subscription" do
    it "starts a Stripe Checkout session and redirects the user to it" do
      band = create(:band, :approved)
      user = create(:user)
      sign_in user

      product = instance_double(Stripe::Product, id: "prod_1")
      price = instance_double(Stripe::Price, id: "price_1")
      customer = instance_double(Stripe::Customer, id: "cus_1")
      session = instance_double(Stripe::Checkout::Session, id: "cs_1", url: "https://checkout.stripe.com/pay/cs_1")

      allow(products_service).to receive(:create).and_return(product)
      allow(prices_service).to receive(:create).and_return(price)
      allow(customers_service).to receive(:create).and_return(customer)
      allow(sessions_service).to receive(:create).and_return(session)

      post band_subscription_path(band), params: { subscription: { level: "supporter" } }

      expect(response).to redirect_to("https://checkout.stripe.com/pay/cs_1")

      subscription = Subscription.find_by(band: band, user: user)
      expect(subscription).to be_present
      expect(subscription.level).to eq("supporter")
      expect(subscription.status).to eq("pending")
      expect(subscription.stripe_checkout_session_id).to eq("cs_1")
      expect(subscription.stripe_customer_id).to eq("cus_1")

      expect(sessions_service).to have_received(:create).with(
        hash_including(
          mode: "subscription",
          customer: "cus_1",
          line_items: [ { price: "price_1", quantity: 1 } ]
        )
      )
    end

    it "reuses an existing BandMembershipPrice instead of creating a new Stripe product" do
      band = create(:band, :approved)
      create(:band_membership_price, band: band, level: :fan, stripe_price_id: "price_cached")
      user = create(:user)
      sign_in user

      customer = instance_double(Stripe::Customer, id: "cus_1")
      session = instance_double(Stripe::Checkout::Session, id: "cs_1", url: "https://checkout.stripe.com/pay/cs_1")
      allow(products_service).to receive(:create)
      allow(customers_service).to receive(:create).and_return(customer)
      allow(sessions_service).to receive(:create).and_return(session)

      post band_subscription_path(band), params: { subscription: { level: "fan" } }

      expect(products_service).not_to have_received(:create)
      expect(sessions_service).to have_received(:create).with(
        hash_including(line_items: [ { price: "price_cached", quantity: 1 } ])
      )
    end

    it "reuses the user's existing Stripe customer id instead of creating a new one" do
      band = create(:band, :approved)
      user = create(:user, stripe_customer_id: "cus_existing")
      sign_in user

      product = instance_double(Stripe::Product, id: "prod_1")
      price = instance_double(Stripe::Price, id: "price_1")
      session = instance_double(Stripe::Checkout::Session, id: "cs_1", url: "https://checkout.stripe.com/pay/cs_1")
      allow(products_service).to receive(:create).and_return(product)
      allow(prices_service).to receive(:create).and_return(price)
      allow(customers_service).to receive(:create)
      allow(sessions_service).to receive(:create).and_return(session)

      post band_subscription_path(band), params: { subscription: { level: "fan" } }

      expect(customers_service).not_to have_received(:create)
      expect(Subscription.find_by(band: band, user: user).stripe_customer_id).to eq("cus_existing")
    end

    it "does not allow starting a subscription for a band that is not approved" do
      band = create(:band)
      user = create(:user)
      sign_in user

      post band_subscription_path(band), params: { subscription: { level: "fan" } }

      expect(response).to have_http_status(:not_found)
      expect(Subscription.find_by(band: band, user: user)).to be_nil
    end

    it "requires authentication" do
      band = create(:band, :approved)

      post band_subscription_path(band), params: { subscription: { level: "fan" } }

      expect(response).to redirect_to(new_user_session_path)
    end

    it "redirects back with an alert when Stripe raises an error" do
      band = create(:band, :approved)
      user = create(:user)
      sign_in user

      allow(products_service).to receive(:create).and_raise(Stripe::APIConnectionError.new("network down"))

      post band_subscription_path(band), params: { subscription: { level: "fan" } }

      expect(response).to redirect_to(public_band_path(band.slug))
      expect(Subscription.find_by(band: band, user: user)).to be_nil
    end
  end
end
