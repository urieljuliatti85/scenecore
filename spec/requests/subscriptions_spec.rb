require "rails_helper"

RSpec.describe "Subscriptions", type: :request do
  let(:products_service) { instance_double(Stripe::ProductService) }
  let(:prices_service) { instance_double(Stripe::PriceService) }
  let(:customers_service) { instance_double(Stripe::CustomerService) }
  let(:sessions_service) { instance_double(Stripe::Checkout::SessionService) }
  let(:checkout) { instance_double(Stripe::CheckoutService, sessions: sessions_service) }
  let(:subscriptions_service) { instance_double(Stripe::SubscriptionService) }
  let(:v1) do
    instance_double(Stripe::V1Services, products: products_service, prices: prices_service,
                                         customers: customers_service, checkout: checkout,
                                         subscriptions: subscriptions_service)
  end
  let(:stripe_client) { instance_double(Stripe::StripeClient, v1: v1) }

  before do
    allow(StripeClient).to receive(:instance).and_return(stripe_client)
  end

  describe "POST /bands/:band_id/subscription" do
    it "starts a Stripe Checkout session and redirects the user to it" do
      band = create(:band, :approved, :payouts_ready)
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
      band = create(:band, :approved, :payouts_ready)
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
      band = create(:band, :approved, :payouts_ready)
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

    # ADR-008: each monthly charge splits at source, so the band's 85%
    # reaches its own Stripe account rather than landing in SceneCore's and
    # waiting on a manual payout.
    it "routes the charge to the band's connected account" do
      band = create(:band, :approved, :payouts_ready)
      create(:band_membership_price, band: band, level: :fan, stripe_price_id: "price_fan")
      user = create(:user)
      sign_in user

      customer = instance_double(Stripe::Customer, id: "cus_1")
      session = instance_double(Stripe::Checkout::Session, id: "cs_1", url: "https://checkout.stripe.com/pay/cs_1")
      allow(customers_service).to receive(:create).and_return(customer)
      allow(sessions_service).to receive(:create).and_return(session)

      post band_subscription_path(band), params: { subscription: { level: "fan" } }

      expect(sessions_service).to have_received(:create).with(
        hash_including(
          subscription_data: {
            application_fee_percent: 15,
            transfer_data: { destination: band.stripe_connect_account_id }
          }
        )
      )
    end

    # A band that has not finished onboarding has nowhere to receive its
    # share, so the fan is stopped before any charge exists rather than
    # being signed into an arrangement that cannot pay the band.
    it "refuses a band whose Connect account Stripe has not cleared" do
      band = create(:band, :approved)
      user = create(:user)
      sign_in user

      post band_subscription_path(band), params: { subscription: { level: "fan" } }

      expect(response).to redirect_to(public_band_path(band.slug))
      expect(flash[:alert]).to include("can't take payments")
      expect(Subscription.find_by(band: band, user: user)).to be_nil
    end

    it "refuses a band whose Connect account is restricted" do
      band = create(:band, :approved, :payouts_ready, stripe_connect_status: :restricted)
      user = create(:user)
      sign_in user

      post band_subscription_path(band), params: { subscription: { level: "fan" } }

      expect(flash[:alert]).to include("can't take payments")
      expect(Subscription.find_by(band: band, user: user)).to be_nil
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
      band = create(:band, :approved, :payouts_ready)

      post band_subscription_path(band), params: { subscription: { level: "fan" } }

      expect(response).to redirect_to(new_user_session_path)
    end

    it "redirects back with an alert when Stripe raises an error" do
      band = create(:band, :approved, :payouts_ready)
      user = create(:user)
      sign_in user

      allow(products_service).to receive(:create).and_raise(Stripe::APIConnectionError.new("network down"))

      post band_subscription_path(band), params: { subscription: { level: "fan" } }

      expect(response).to redirect_to(public_band_path(band.slug))
      expect(Subscription.find_by(band: band, user: user)).to be_nil
    end

    it "switches the existing Stripe subscription's price instead of starting a second subscription when the fan already has an active one" do
      band = create(:band, :approved, :payouts_ready)
      create(:band_membership_price, band: band, level: :supporter, stripe_price_id: "price_supporter")
      user = create(:user)
      subscription = create(:subscription, :active, band: band, user: user, level: :fan, stripe_subscription_id: "sub_1")
      create(:membership, band: band, user: user, level: :fan, status: :active)
      sign_in user

      item = instance_double(Stripe::SubscriptionItem, id: "si_1", price: instance_double(Stripe::Price, id: "price_fan"))
      items = double(data: [ item ])
      existing_subscription = instance_double(Stripe::Subscription, items: items)
      allow(subscriptions_service).to receive(:retrieve).with("sub_1").and_return(existing_subscription)
      allow(subscriptions_service).to receive(:update)

      post band_subscription_path(band), params: { subscription: { level: "supporter" } }

      expect(subscriptions_service).to have_received(:update).with(
        "sub_1", items: [ { id: "si_1", price: "price_supporter" } ]
      )
      expect(subscription.reload.level).to eq("supporter")
      expect(Membership.find_by(band: band, user: user).level).to eq("supporter")
      expect(response).to redirect_to(public_band_path(band.slug))
    end

    it "does not switch the subscription when the fan re-selects the level they already have" do
      band = create(:band, :approved, :payouts_ready)
      create(:band_membership_price, band: band, level: :fan, stripe_price_id: "price_fan")
      user = create(:user)
      subscription = create(:subscription, :active, band: band, user: user, level: :fan, stripe_subscription_id: "sub_1")
      sign_in user

      item = instance_double(Stripe::SubscriptionItem, id: "si_1", price: instance_double(Stripe::Price, id: "price_fan"))
      items = double(data: [ item ])
      existing_subscription = instance_double(Stripe::Subscription, items: items)
      allow(subscriptions_service).to receive(:retrieve).with("sub_1").and_return(existing_subscription)
      allow(subscriptions_service).to receive(:update)

      post band_subscription_path(band), params: { subscription: { level: "fan" } }

      expect(subscriptions_service).not_to have_received(:update)
      expect(subscription.reload.level).to eq("fan")
      expect(response).to redirect_to(public_band_path(band.slug))
    end

    it "redirects back with an alert when switching the subscription level fails on Stripe" do
      band = create(:band, :approved, :payouts_ready)
      create(:band_membership_price, band: band, level: :supporter, stripe_price_id: "price_supporter")
      user = create(:user)
      subscription = create(:subscription, :active, band: band, user: user, level: :fan, stripe_subscription_id: "sub_1")
      sign_in user

      allow(subscriptions_service).to receive(:retrieve).with("sub_1").and_raise(Stripe::InvalidRequestError.new("no such subscription", "id"))

      post band_subscription_path(band), params: { subscription: { level: "supporter" } }

      expect(response).to redirect_to(public_band_path(band.slug))
      expect(subscription.reload.level).to eq("fan")
    end
  end

  describe "DELETE /bands/:band_id/subscription" do
    it "cancels the subscription on Stripe and marks it (and the membership) cancelled locally" do
      band = create(:band, :approved, :payouts_ready)
      user = create(:user)
      subscription = create(:subscription, :active, band: band, user: user, stripe_subscription_id: "sub_1")
      create(:membership, band: band, user: user, level: subscription.level, status: :active)
      sign_in user

      allow(subscriptions_service).to receive(:cancel)

      delete band_subscription_path(band)

      expect(subscriptions_service).to have_received(:cancel).with("sub_1")
      expect(subscription.reload.status).to eq("cancelled")
      expect(Membership.find_by(band: band, user: user).status).to eq("cancelled")
      expect(response).to redirect_to(public_band_path(band.slug))
    end

    it "does not call Stripe when the subscription never completed checkout" do
      band = create(:band, :approved, :payouts_ready)
      user = create(:user)
      create(:subscription, band: band, user: user, stripe_subscription_id: nil)
      sign_in user

      allow(subscriptions_service).to receive(:cancel)

      delete band_subscription_path(band)

      expect(subscriptions_service).not_to have_received(:cancel)
      expect(response).to redirect_to(public_band_path(band.slug))
    end

    it "redirects with an alert when Stripe raises an error" do
      band = create(:band, :approved, :payouts_ready)
      user = create(:user)
      subscription = create(:subscription, :active, band: band, user: user, stripe_subscription_id: "sub_1")
      sign_in user

      allow(subscriptions_service).to receive(:cancel).and_raise(Stripe::InvalidRequestError.new("no such subscription", "id"))

      delete band_subscription_path(band)

      expect(response).to redirect_to(public_band_path(band.slug))
      expect(subscription.reload.status).to eq("active")
    end

    it "returns 404 when the user has no subscription with the band" do
      band = create(:band, :approved, :payouts_ready)
      user = create(:user)
      sign_in user

      delete band_subscription_path(band)

      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 when trying to cancel another user's subscription (the lookup is scoped to current_user)" do
      band = create(:band, :approved, :payouts_ready)
      subscription = create(:subscription, :active, band: band, stripe_subscription_id: "sub_1")
      outsider = create(:user)
      sign_in outsider

      delete band_subscription_path(band)

      expect(response).to have_http_status(:not_found)
      expect(subscription.reload.status).to eq("active")
    end

    it "requires authentication" do
      band = create(:band, :approved, :payouts_ready)
      create(:subscription, :active, band: band)

      delete band_subscription_path(band)

      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "GET /subscriptions" do
    it "lists only the signed-in user's subscriptions" do
      user = create(:user)
      band = create(:band, :approved, name: "My Band")
      create(:subscription, :active, user: user, band: band, level: :supporter)
      create(:subscription, :active, band: create(:band, :approved, name: "Someone Else's Band"))
      sign_in user

      get subscriptions_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("My Band")
      expect(response.body).not_to include("Someone Else's Band")
    end

    it "shows an empty state when the user has no subscriptions" do
      user = create(:user)
      sign_in user

      get subscriptions_path

      expect(response.body).to include("You haven")
      expect(response.body).to include("subscribed to any bands yet")
    end

    it "requires authentication" do
      get subscriptions_path

      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
