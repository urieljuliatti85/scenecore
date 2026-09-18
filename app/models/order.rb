class Order < ApplicationRecord
  REFUNDABLE_STATUSES = %w[paid processing completed].freeze
  REFUND_STATUSES = %w[pending requires_action succeeded failed canceled].freeze

  belongs_to :user
  belongs_to :band
  has_many :order_items, dependent: :destroy
  has_one :shipping_address, dependent: :destroy

  enum :status, { pending: "pending", paid: "paid", processing: "processing",
                   completed: "completed", cancelled: "cancelled", refunded: "refunded" },
       default: :pending, validate: true

  validates :subtotal_cents, :shipping_cents, :total_cents, :platform_fee_cents,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :refund_status, inclusion: { in: REFUND_STATUSES }, allow_nil: true

  # Orders a band is responsible for: money has arrived, so the goods are
  # owed. A pending order is still Stripe's to confirm and must not look
  # like something to pack.
  scope :awaiting_band, -> { where(status: [ :paid, :processing ]).order(created_at: :asc) }

  # The fulfilment steps a band can take, in order. Refunding and
  # cancelling are deliberately absent: both move money back and need the
  # refund policy that docs/product.md §7 still leaves open.
  FULFILMENT_TRANSITIONS = {
    "paid" => "processing",
    "processing" => "completed"
  }.freeze

  def next_fulfilment_status
    FULFILMENT_TRANSITIONS[status]
  end

  def advance_fulfilment!
    next_status = next_fulfilment_status
    raise ArgumentError, "Order #{id} cannot be advanced from #{status}" if next_status.nil?

    update!(status: next_status)
  end

  # A full Store refund is available only after Stripe has taken payment.
  # The Checkout Session is enough for older orders: the refund service can
  # retrieve its PaymentIntent when it was created before we persisted that
  # identifier locally.
  def refundable?
    total_cents.positive? && status.in?(REFUNDABLE_STATUSES) &&
      stripe_checkout_session_id.present? && stripe_refund_id.blank?
  end

  def refund_pending?
    !refunded? && stripe_refund_id.present? && refund_status.in?(%w[pending requires_action succeeded])
  end

  def refund_failed?
    !refunded? && refund_status.in?(%w[failed canceled])
  end
end
