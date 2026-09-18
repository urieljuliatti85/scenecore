# Stripe webhooks arrive with no user session and no CSRF token — this
# deliberately does not inherit from ApplicationController, which would
# force sign-in. Authenticity here is Stripe-Signature verification
# (see verified_event below), not the CSRF token this skips.
class StripeWebhooksController < ActionController::Base
  skip_forgery_protection

  V2_RECIPIENT_CAPABILITY_EVENT =
    "v2.core.account[configuration.recipient].capability_status_updated".freeze

  def create
    event = verified_event
    return head(:bad_request) if event.nil?

    process_event(event)
    head :ok
  rescue StripeWebhookEvent::DuplicateEvent
    # Same event delivered more than once (Stripe's own retry policy, or
    # simple redelivery) — already processed, tell Stripe it succeeded
    # so it stops retrying instead of erroring here.
    head :ok
  end

  private

  def verified_event
    payload = request.body.read
    signature = request.headers["Stripe-Signature"]

    case JSON.parse(payload)["object"]
    when "event"
      Stripe::Webhook.construct_event(payload, signature, snapshot_webhook_secret)
    when "v2.core.event"
      StripeClient.instance.parse_event_notification(payload, signature, thin_webhook_secret)
    end
  rescue JSON::ParserError, Stripe::SignatureVerificationError, ArgumentError
    nil
  end

  def snapshot_webhook_secret
    Rails.application.credentials.dig(:stripe, :webhook_secret)
  end

  # Stripe does not allow v1 snapshot events and v2 thin events in the same
  # event destination. Both destinations can post to this controller, but each
  # has its own signing secret.
  def thin_webhook_secret
    ENV["STRIPE_CONNECT_WEBHOOK_SECRET"].presence ||
      Rails.application.credentials.dig(:stripe, :connect_webhook_secret)
  end

  def process_event(event)
    # Recording and applying an event are one unit. If a handler fails, the
    # marker rolls back too, so Stripe can retry instead of being told that a
    # half-applied financial event was already processed.
    StripeWebhookEvent.transaction do
      StripeWebhookEvent.record!(stripe_event_id: event.id, event_type: event.type)

      case event.type
      when "checkout.session.completed"
        handle_checkout_completed(event.data.object)
      when "customer.subscription.updated"
        StripeSubscriptionUpdatedHandler.call(event.data.object)
      when "customer.subscription.deleted"
        StripeSubscriptionDeletedHandler.call(event.data.object)
      when "account.updated"
        # Only ever sent for a connected account (ADR-007's Store/Connect
        # flow) — the platform account itself does not receive its own
        # account.updated events, so no `event.account` check is needed to
        # tell this apart from Subscriptions' platform-level events above.
        StripeConnectAccountUpdatedHandler.call(event.data.object)
      when V2_RECIPIENT_CAPABILITY_EVENT
        handle_v2_connect_capability_updated(event)
      when "refund.created", "refund.updated", "refund.failed"
        StripeStoreRefundHandler.call(event.data.object)
      end
    end
  end

  # Accounts created through Stripe's v2 API emit thin notifications rather
  # than v1 snapshot events. The notification is signed but intentionally
  # carries only a reference, so re-read the account through the existing
  # refresher instead of trusting incomplete event data. That read asks for
  # the recipient capability explicitly and drives the same status handler
  # used by the Payments page fallback.
  def handle_v2_connect_capability_updated(event)
    band = Band.find_by(stripe_connect_account_id: event.related_object.id)
    StripeConnectStatusRefresher.call(band) if band
  end

  # Store checkout (ADR-007) and Subscription checkout both complete as
  # checkout.session.completed on this same endpoint. The Store's sessions
  # are destination charges on the platform account, so the event does not
  # identify itself as belonging to a connected account — the order's own
  # session id is what distinguishes it.
  def handle_checkout_completed(session)
    if Order.exists?(stripe_checkout_session_id: session.id)
      StripeStorePaymentHandler.call(session)
    else
      StripeCheckoutCompletedHandler.call(session)
    end
  end
end
