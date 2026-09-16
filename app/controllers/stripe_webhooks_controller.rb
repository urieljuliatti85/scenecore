# Stripe webhooks arrive with no user session and no CSRF token — this
# deliberately does not inherit from ApplicationController, which would
# force sign-in. Authenticity here is Stripe-Signature verification
# (see verified_event below), not the CSRF token this skips.
class StripeWebhooksController < ActionController::Base
  skip_forgery_protection

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
    endpoint_secret = Rails.application.credentials.dig(:stripe, :webhook_secret)

    Stripe::Webhook.construct_event(payload, signature, endpoint_secret)
  rescue JSON::ParserError, Stripe::SignatureVerificationError
    nil
  end

  def process_event(event)
    StripeWebhookEvent.record!(stripe_event_id: event.id, event_type: event.type)

    case event.type
    when "checkout.session.completed"
      StripeCheckoutCompletedHandler.call(event.data.object)
    when "customer.subscription.updated"
      StripeSubscriptionUpdatedHandler.call(event.data.object)
    when "customer.subscription.deleted"
      StripeSubscriptionDeletedHandler.call(event.data.object)
    end
  end
end
