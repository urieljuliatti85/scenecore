class TicketOrder < ApplicationRecord
  belongs_to :ticket_batch
  belongs_to :user
  has_many :tickets, dependent: :restrict_with_error

  enum :status, { pending: "pending", paid: "paid", expired: "expired" },
       default: :pending, validate: true

  validates :quantity, numericality: {
    only_integer: true,
    greater_than: 0,
    less_than_or_equal_to: TicketBatch::MAXIMUM_PER_ORDER
  }
  validates :unit_price_cents, :total_cents, :platform_fee_cents,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :expires_at, presence: true

  delegate :event, to: :ticket_batch
  delegate :band, to: :event

  def payment_pending?
    pending? && expires_at.future?
  end
end
