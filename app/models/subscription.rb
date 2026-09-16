class Subscription < ApplicationRecord
  belongs_to :user
  belongs_to :band

  enum :level, Membership::LEVELS.index_with(&:itself), validate: true
  enum :status, { pending: "pending", active: "active", past_due: "past_due", cancelled: "cancelled", expired: "expired" },
       default: :pending, validate: true

  validates :user_id, uniqueness: { scope: :band_id, message: "already has a subscription with this band" }
  validates :stripe_customer_id, presence: true
end
