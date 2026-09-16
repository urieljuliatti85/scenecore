# Keeps a Subscription (and the Membership it grants) in sync with
# Stripe's own subscription status — e.g. a card declines on renewal
# and Stripe marks the subscription past_due, or it later recovers.
class StripeSubscriptionUpdatedHandler
  STATUS_MAP = {
    "active" => :active,
    "trialing" => :active,
    "past_due" => :past_due,
    "unpaid" => :past_due,
    "canceled" => :cancelled,
    "incomplete_expired" => :expired
  }.freeze

  def self.call(stripe_subscription)
    new(stripe_subscription).call
  end

  def initialize(stripe_subscription)
    @stripe_subscription = stripe_subscription
  end

  def call
    subscription = Subscription.find_by(stripe_subscription_id: @stripe_subscription.id)
    return if subscription.nil?

    new_status = STATUS_MAP[@stripe_subscription.status]
    return if new_status.nil?

    subscription.update!(status: new_status)

    membership = subscription.band.memberships.find_by(user: subscription.user)
    return if membership.nil?

    membership.update!(status: new_status == :active ? :active : :paused)
  end
end
