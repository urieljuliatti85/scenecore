# Ends a fan's paid relationship with a band: the Stripe subscription
# stops billing, and both the Subscription and the Membership it granted
# are marked cancelled.
#
# Cancelling only the Membership would leave Stripe charging a fan who no
# longer has access, so every path that ends a paid membership — the fan
# doing it themselves, or a platform administrator doing it for them —
# goes through here.
class SubscriptionCanceller
  Error = Class.new(StandardError)

  def self.call(band:, user:)
    new(band: band, user: user).call
  end

  def initialize(band:, user:)
    @band = band
    @user = user
  end

  def call
    stop_billing

    subscription&.update!(status: :cancelled)
    membership&.update!(status: :cancelled)
  end

  private

  def subscription
    return @subscription if defined?(@subscription)

    @subscription = @band.subscriptions.find_by(user: @user)
  end

  def membership
    return @membership if defined?(@membership)

    @membership = @band.memberships.find_by(user: @user)
  end

  # A membership granted by the band directly has no Stripe subscription
  # behind it, and one that never completed checkout has no id yet —
  # neither is an error, there is simply no billing to stop.
  def stop_billing
    return if subscription&.stripe_subscription_id.blank?

    StripeClient.instance.v1.subscriptions.cancel(subscription.stripe_subscription_id)
  rescue Stripe::InvalidRequestError => e
    # Already gone on Stripe's side (cancelled there, or in a test fixture
    # that no longer exists): the local records should still be brought in
    # line rather than leaving the fan with access they stopped paying for.
    raise Error, "Could not cancel the Stripe subscription: #{e.message}" unless e.message.to_s.include?("No such subscription")
  rescue Stripe::StripeError => e
    raise Error, "Could not cancel the Stripe subscription: #{e.message}"
  end
end
