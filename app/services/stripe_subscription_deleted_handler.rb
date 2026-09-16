# A subscription.deleted event means Stripe has fully ended it (the
# final state after cancellation, not the moment the user requests
# cancellation) — the fan's access ends here.
class StripeSubscriptionDeletedHandler
  def self.call(stripe_subscription)
    new(stripe_subscription).call
  end

  def initialize(stripe_subscription)
    @stripe_subscription = stripe_subscription
  end

  def call
    subscription = Subscription.find_by(stripe_subscription_id: @stripe_subscription.id)
    return if subscription.nil?

    subscription.update!(status: :cancelled)

    membership = subscription.band.memberships.find_by(user: subscription.user)
    membership&.update!(status: :cancelled)
  end
end
