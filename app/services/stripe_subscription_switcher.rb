# Switches an existing Stripe subscription to a different price
# (upgrade/downgrade between membership levels) instead of creating a
# second one. Creating a new subscription per level change would leave
# the previous one active and billing — the fan would be charged for
# both.
#
# Stripe prorates the change automatically: the unused part of the old
# level is credited and the new level is debited for the rest of the
# period, so the fan isn't charged a full second period mid-cycle.
class StripeSubscriptionSwitcher
  Error = Class.new(StandardError)

  def self.call(stripe_subscription_id, price_id)
    new(stripe_subscription_id, price_id).call
  end

  def initialize(stripe_subscription_id, price_id)
    @stripe_subscription_id = stripe_subscription_id
    @price_id = price_id
  end

  def call
    subscription = StripeClient.instance.v1.subscriptions.retrieve(@stripe_subscription_id)
    item = subscription.items.data.first
    raise Error, "Stripe subscription #{@stripe_subscription_id} has no items to switch" if item.nil?

    return subscription if item.price.id == @price_id

    # Passing the existing item's id is what makes this a replacement.
    # Omitting it would *add* a second item, leaving both levels billing.
    StripeClient.instance.v1.subscriptions.update(
      @stripe_subscription_id,
      items: [ { id: item.id, price: @price_id } ]
    )
  rescue Stripe::StripeError => e
    raise Error, "Could not change your subscription level: #{e.message}"
  end
end
