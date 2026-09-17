class Order < ApplicationRecord
  # SceneCore's Store commission (ADR-007). Charged as Stripe's
  # application_fee_amount at checkout, and snapshotted onto the order so a
  # later rate change never rewrites what a past order was split at.
  PLATFORM_FEE_RATE = 0.10

  belongs_to :user
  belongs_to :band
  has_many :order_items, dependent: :destroy
  has_one :shipping_address, dependent: :destroy

  enum :status, { pending: "pending", paid: "paid", processing: "processing",
                   completed: "completed", cancelled: "cancelled", refunded: "refunded" },
       default: :pending, validate: true

  validates :subtotal_cents, :shipping_cents, :total_cents, :platform_fee_cents,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
