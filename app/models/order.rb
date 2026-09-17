class Order < ApplicationRecord
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
