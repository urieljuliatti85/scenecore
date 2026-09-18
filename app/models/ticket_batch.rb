class TicketBatch < ApplicationRecord
  MAXIMUM_PER_ORDER = 10

  belongs_to :event
  has_many :ticket_orders, dependent: :restrict_with_error

  validates :name, presence: true
  validates :price_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :quantity_total, numericality: { only_integer: true, greater_than: 0 }
  validate :sales_window_is_ordered
  validate :quantity_covers_existing_commitments

  scope :for_sale, -> { order(:price_cents, :created_at) }

  def on_sale?(at: Time.current)
    event.published? && event.starts_at > at &&
      (sales_start_at.nil? || sales_start_at <= at) &&
      (sales_end_at.nil? || sales_end_at > at) &&
      remaining_quantity(at: at).positive?
  end

  def remaining_quantity(at: Time.current)
    sold = ticket_orders.paid.sum(:quantity)
    reserved = ticket_orders.pending.where("expires_at > ?", at).sum(:quantity)
    [ quantity_total - sold - reserved, 0 ].max
  end

  private

  def sales_window_is_ordered
    return if sales_start_at.blank? || sales_end_at.blank? || sales_end_at > sales_start_at

    errors.add(:sales_end_at, "must be after the sales start")
  end

  def quantity_covers_existing_commitments
    return unless persisted? && quantity_total.present?

    committed = ticket_orders.paid.sum(:quantity) +
                ticket_orders.pending.where("expires_at > ?", Time.current).sum(:quantity)
    return if quantity_total >= committed

    errors.add(:quantity_total, "cannot be lower than #{committed} sold or reserved tickets")
  end
end
