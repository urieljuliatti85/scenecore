require "rails_helper"

RSpec.describe "Stripe webhooks", type: :request do
  def post_webhook(event)
    allow(Stripe::Webhook).to receive(:construct_event).and_return(event)
    post stripe_webhooks_path, params: '{"object":"event"}',
      headers: { "Stripe-Signature" => "t=1,v1=fake", "CONTENT_TYPE" => "application/json" }
  end

  def post_v2_webhook(event)
    stripe_client = instance_double(Stripe::StripeClient)
    allow(StripeClient).to receive(:instance).and_return(stripe_client)
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("STRIPE_CONNECT_WEBHOOK_SECRET").and_return("whsec_connect")
    allow(stripe_client).to receive(:parse_event_notification)
      .with('{"object":"v2.core.event"}', "t=1,v1=fake", "whsec_connect")
      .and_return(event)
    allow(Stripe::Webhook).to receive(:construct_event)
    post stripe_webhooks_path, params: '{"object":"v2.core.event"}',
      headers: { "Stripe-Signature" => "t=1,v1=fake", "CONTENT_TYPE" => "application/json" }
  end

  describe "POST /stripe/webhooks" do
    it "returns 400 when the signature cannot be verified" do
      allow(Stripe::Webhook).to receive(:construct_event)
        .and_raise(Stripe::SignatureVerificationError.new("bad signature", "sig_header"))

      post stripe_webhooks_path, params: '{"object":"event"}',
        headers: { "Stripe-Signature" => "invalid", "CONTENT_TYPE" => "application/json" }

      expect(response).to have_http_status(:bad_request)
    end

    it "returns 400 for a malformed payload" do
      allow(Stripe::Webhook).to receive(:construct_event).and_raise(JSON::ParserError)

      post stripe_webhooks_path, params: "not json", headers: { "Stripe-Signature" => "t=1,v1=fake" }

      expect(response).to have_http_status(:bad_request)
    end

    it "records the event and activates the subscription for checkout.session.completed" do
      subscription = create(:subscription, level: :fan, stripe_checkout_session_id: "cs_1")
      session = instance_double(Stripe::Checkout::Session, id: "cs_1", payment_status: "paid", subscription: "sub_1")
      event = instance_double(Stripe::Event, id: "evt_1", type: "checkout.session.completed",
        data: instance_double(Stripe::Event::Data, object: session))

      post_webhook(event)

      expect(response).to have_http_status(:ok)
      expect(StripeWebhookEvent.exists?(stripe_event_id: "evt_1")).to be true
      expect(subscription.reload.status).to eq("active")
    end

    it "returns 200 without reprocessing when the event was already recorded" do
      create(:stripe_webhook_event, stripe_event_id: "evt_1")
      session = instance_double(Stripe::Checkout::Session, id: "cs_1", payment_status: "paid", subscription: "sub_1")
      event = instance_double(Stripe::Event, id: "evt_1", type: "checkout.session.completed",
        data: instance_double(Stripe::Event::Data, object: session))

      post_webhook(event)

      expect(response).to have_http_status(:ok)
      expect(StripeWebhookEvent.where(stripe_event_id: "evt_1").count).to eq(1)
    end

    # A Store session and a Subscription session arrive as the same event
    # type on the same endpoint. The order's own session id is what tells
    # them apart, so a Store payment must not fall through to the
    # subscription handler and be silently ignored.
    it "marks a Store order paid for checkout.session.completed" do
      band = create(:band, :approved, stripe_connect_status: :active, stripe_connect_account_id: "acct_1")
      product = create(:product, :published, band: band)
      variant = product.variants.create!(name: "Standard", sku: "V-9", price_cents: 12_000, stock_quantity: 4)
      order = create(:user).orders.create!(
        band: band, subtotal_cents: 12_000, shipping_cents: 0, total_cents: 12_000,
        platform_fee_cents: 1_200, stripe_checkout_session_id: "cs_store_9"
      )
      order.order_items.create!(product_variant: variant, product_name: product.name,
                                variant_name: "Standard", unit_price_cents: 12_000, quantity: 1)

      session = instance_double(Stripe::Checkout::Session, id: "cs_store_9", payment_status: "paid",
                                                          payment_intent: "pi_store_9")
      event = instance_double(Stripe::Event, id: "evt_store_1", type: "checkout.session.completed",
        data: instance_double(Stripe::Event::Data, object: session))

      post_webhook(event)

      expect(response).to have_http_status(:ok)
      expect(order.reload).to be_paid
      expect(order.stripe_payment_intent_id).to eq("pi_store_9")
      expect(variant.reload.stock_quantity).to eq(3)
    end

    it "marks a Store order refunded only after Stripe confirms the refund" do
      order = create(:order, :paid, stripe_checkout_session_id: "cs_store_refund",
                     stripe_payment_intent_id: "pi_store_refund", stripe_refund_id: "re_store_1",
                     refund_status: "pending")
      refund = instance_double(Stripe::Refund, id: "re_store_1", status: "succeeded",
                                               payment_intent: "pi_store_refund",
                                               metadata: { "order_id" => order.id.to_s })
      event = instance_double(Stripe::Event, id: "evt_refund_1", type: "refund.updated",
                                             data: instance_double(Stripe::Event::Data, object: refund))

      post_webhook(event)

      expect(response).to have_http_status(:ok)
      expect(order.reload).to be_refunded
      expect(order.refund_status).to eq("succeeded")
      expect(order.refunded_at).to be_present
    end

    it "does not record a refund event when applying it fails, so Stripe can retry" do
      refund = instance_double(Stripe::Refund)
      event = instance_double(Stripe::Event, id: "evt_refund_retry", type: "refund.updated",
                                             data: instance_double(Stripe::Event::Data, object: refund))
      allow(StripeStoreRefundHandler).to receive(:call).and_raise(ActiveRecord::Deadlocked)

      expect { post_webhook(event) }.to raise_error(ActiveRecord::Deadlocked)
      expect(StripeWebhookEvent.exists?(stripe_event_id: "evt_refund_retry")).to be false
    end

    it "does not touch a Store order when the session belongs to a subscription" do
      subscription = create(:subscription, level: :fan, stripe_checkout_session_id: "cs_sub_9")
      session = instance_double(Stripe::Checkout::Session, id: "cs_sub_9", payment_status: "paid", subscription: "sub_9")
      event = instance_double(Stripe::Event, id: "evt_sub_9", type: "checkout.session.completed",
        data: instance_double(Stripe::Event::Data, object: session))

      post_webhook(event)

      expect(subscription.reload.status).to eq("active")
      expect(Order.count).to be_zero
    end

    it "updates the subscription for customer.subscription.updated" do
      subscription = create(:subscription, :active, stripe_subscription_id: "sub_1")
      stripe_subscription = instance_double(Stripe::Subscription, id: "sub_1", status: "past_due")
      event = instance_double(Stripe::Event, id: "evt_2", type: "customer.subscription.updated",
        data: instance_double(Stripe::Event::Data, object: stripe_subscription))

      post_webhook(event)

      expect(response).to have_http_status(:ok)
      expect(subscription.reload.status).to eq("past_due")
    end

    it "cancels the subscription for customer.subscription.deleted" do
      subscription = create(:subscription, :active, stripe_subscription_id: "sub_1")
      stripe_subscription = instance_double(Stripe::Subscription, id: "sub_1")
      event = instance_double(Stripe::Event, id: "evt_3", type: "customer.subscription.deleted",
        data: instance_double(Stripe::Event::Data, object: stripe_subscription))

      post_webhook(event)

      expect(response).to have_http_status(:ok)
      expect(subscription.reload.status).to eq("cancelled")
    end

    it "syncs a band's connect status for account.updated (ADR-007)" do
      band = create(:band, stripe_connect_account_id: "acct_1", stripe_connect_status: :onboarding)
      account = instance_double(
        Stripe::Account, id: "acct_1", charges_enabled: true, payouts_enabled: true,
        requirements: Stripe::StripeObject.construct_from(disabled_reason: nil)
      )
      event = instance_double(Stripe::Event, id: "evt_connect_1", type: "account.updated",
        data: instance_double(Stripe::Event::Data, object: account))

      post_webhook(event)

      expect(response).to have_http_status(:ok)
      expect(band.reload).to be_stripe_connect_active
    end

    it "verifies and processes the v2 recipient capability event" do
      band = create(:band, stripe_connect_account_id: "acct_v2", stripe_connect_status: :onboarding)
      notification = instance_double(
        Stripe::Events::V2CoreAccountIncludingConfigurationRecipientCapabilityStatusUpdatedEventNotification,
        id: "evt_v2_connect_1",
        type: StripeWebhooksController::V2_RECIPIENT_CAPABILITY_EVENT,
        related_object: double(id: "acct_v2")
      )
      allow(StripeConnectStatusRefresher).to receive(:call) do |refreshed_band|
        refreshed_band.update!(stripe_connect_status: :active)
      end

      post_v2_webhook(notification)

      expect(response).to have_http_status(:ok)
      expect(band.reload).to be_stripe_connect_active
      expect(StripeWebhookEvent.exists?(stripe_event_id: "evt_v2_connect_1")).to be true
      expect(Stripe::Webhook).not_to have_received(:construct_event)
    end

    it "returns 400 when a v2 notification signature cannot be verified" do
      stripe_client = instance_double(Stripe::StripeClient)
      allow(StripeClient).to receive(:instance).and_return(stripe_client)
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("STRIPE_CONNECT_WEBHOOK_SECRET").and_return("whsec_connect")
      allow(stripe_client).to receive(:parse_event_notification)
        .and_raise(Stripe::SignatureVerificationError.new("bad signature", "sig_header"))

      post stripe_webhooks_path, params: '{"object":"v2.core.event"}',
        headers: { "Stripe-Signature" => "invalid", "CONTENT_TYPE" => "application/json" }

      expect(response).to have_http_status(:bad_request)
      expect(StripeWebhookEvent.count).to be_zero
    end

    it "records a v2 capability event for an unknown account without failing" do
      notification = instance_double(
        Stripe::Events::V2CoreAccountIncludingConfigurationRecipientCapabilityStatusUpdatedEventNotification,
        id: "evt_v2_unknown",
        type: StripeWebhooksController::V2_RECIPIENT_CAPABILITY_EVENT,
        related_object: double(id: "acct_unknown")
      )
      allow(StripeConnectStatusRefresher).to receive(:call)

      post_v2_webhook(notification)

      expect(response).to have_http_status(:ok)
      expect(StripeConnectStatusRefresher).not_to have_received(:call)
      expect(StripeWebhookEvent.exists?(stripe_event_id: "evt_v2_unknown")).to be true
    end

    it "returns 200 and records the event for an event type it doesn't handle" do
      event = instance_double(Stripe::Event, id: "evt_4", type: "invoice.paid",
        data: instance_double(Stripe::Event::Data, object: instance_double(Stripe::StripeObject)))

      post_webhook(event)

      expect(response).to have_http_status(:ok)
      expect(StripeWebhookEvent.exists?(stripe_event_id: "evt_4")).to be true
    end

    it "does not require authentication" do
      event = instance_double(Stripe::Event, id: "evt_5", type: "invoice.paid",
        data: instance_double(Stripe::Event::Data, object: instance_double(Stripe::StripeObject)))

      post_webhook(event)

      expect(response).not_to have_http_status(:redirect)
    end
  end
end
