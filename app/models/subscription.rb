class Subscription < ApplicationRecord
  # SceneCore's membership commission (ADR-008). Higher than the Store's
  # 10% because the platform hosts and serves that relationship every
  # month rather than settling a one-off sale. Applied as Stripe's
  # application_fee_percent so each monthly charge splits at source.
  PLATFORM_FEE_PERCENT = 15

  belongs_to :user
  belongs_to :band

  enum :level, Membership::LEVELS.index_with(&:itself), validate: true
  enum :status, { pending: "pending", active: "active", past_due: "past_due", cancelled: "cancelled", expired: "expired" },
       default: :pending, validate: true

  validates :user_id, uniqueness: { scope: :band_id, message: "already has a subscription with this band" }
  validates :stripe_customer_id, presence: true

  BILLING_STATUSES = %w[active past_due].freeze

  # Still charging the fan while the membership it paid for is not granting
  # access — cancelled, paused, or gone entirely. Before
  # SubscriptionCanceller, cancelling a membership from the admin screen
  # left the Stripe subscription running, which is how these arose.
  #
  # past_due counts as billing: Stripe is still retrying the charge.
  scope :orphaned, lambda {
    where(status: BILLING_STATUSES)
      .where.not(
        Membership.where("memberships.user_id = subscriptions.user_id")
                  .where("memberships.band_id = subscriptions.band_id")
                  .where(status: :active)
                  .arel.exists
      )
  }
end
