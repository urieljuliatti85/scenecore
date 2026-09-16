# Activates a Subscription (and the Membership it grants) once Stripe
# confirms the Checkout Session actually completed. Per Stripe's own
# guidance, fulfillment belongs here — not on the success page the
# browser is redirected to, which the buyer could skip or which could
# fail to load without payment ever being affected.
class StripeCheckoutCompletedHandler
  def self.call(session)
    new(session).call
  end

  def initialize(session)
    @session = session
  end

  def call
    return unless @session.payment_status.in?(%w[paid no_payment_required])

    subscription = Subscription.find_by(stripe_checkout_session_id: @session.id)
    return if subscription.nil?

    subscription.update!(status: :active, stripe_subscription_id: @session.subscription)

    membership = subscription.band.memberships.find_or_initialize_by(user: subscription.user)
    membership.level = subscription.level
    membership.status = :active
    membership.save!
  end
end
