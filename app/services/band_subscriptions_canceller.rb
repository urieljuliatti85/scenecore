# Stops billing every fan subscription still active on a band, for when
# the band is suspended: the band's pages go dark immediately, but nothing
# else stopped a fan from being charged for access they can no longer use.
# Each subscription goes through SubscriptionCanceller — the same path a
# fan or Admin::MembershipsController uses — so Stripe, the Subscription,
# and the Membership all end up cancelled together.
#
# Reactivating a band does not run the reverse of this: a cancelled Stripe
# subscription cannot be un-cancelled, so a fan who wants back in checks
# out again. That is a deliberate product decision, not an oversight.
class BandSubscriptionsCanceller
  Result = Data.define(:cancelled_count, :failed_count)

  def self.call(band)
    new(band).call
  end

  def initialize(band)
    @band = band
  end

  def call
    total = subscriptions.count
    failed = 0

    # Loaded up front: cancelling moves each row out of the `subscriptions`
    # scope, so iterating the relation directly would skip records as it
    # goes.
    subscriptions.to_a.each do |subscription|
      SubscriptionCanceller.call(band: @band, user: subscription.user)
    rescue SubscriptionCanceller::Error => e
      # One unreachable subscription should not stop the rest: every fan
      # left billing is money still being taken from someone who can no
      # longer see what they are paying for.
      Rails.logger.warn("Could not cancel subscription ##{subscription.id} for band #{@band.id}: #{e.message}")
      failed += 1
    end

    Result.new(cancelled_count: total - failed, failed_count: failed)
  end

  private

  def subscriptions
    @band.subscriptions.where(status: Subscription::BILLING_STATUSES)
  end
end
