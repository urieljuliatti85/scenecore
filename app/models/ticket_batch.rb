class TicketBatch < ApplicationRecord
  MAXIMUM_PER_ORDER = 10

  belongs_to :event
  has_many :ticket_orders, dependent: :restrict_with_error

  validates :name, presence: true
  validates :price_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :quantity_total, numericality: { only_integer: true, greater_than: 0 }
  validate :sales_window_is_ordered
  validate :membership_sales_windows_are_ordered
  validate :quantity_covers_existing_commitments

  scope :for_sale, -> { order(:price_cents, :created_at) }

  def on_sale?(at: Time.current)
    on_sale_to?(nil, at: at)
  end

  def on_sale_to?(user, at: Time.current)
    starts_at = sale_starts_at_for(user)
    event.published? && event.starts_at > at &&
      (starts_at.nil? || starts_at <= at) &&
      (sales_end_at.nil? || sales_end_at > at) &&
      remaining_quantity(at: at).positive?
  end

  def sale_starts_at_for(user)
    membership = event.band.memberships.active.find_by(user: user) if user
    eligible_sales_starts(membership).compact.min
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

  def membership_sales_windows_are_ordered
    member_starts = [ core_member_sales_start_at, supporter_sales_start_at, fan_sales_start_at ]
    return if member_starts.compact.empty?

    if sales_start_at.nil?
      errors.add(:sales_start_at, "is required when membership early access is configured")
      return
    end

    ordered_starts = [ *member_starts, sales_start_at ].compact
    return if ordered_starts.each_cons(2).all? { |earlier, later| earlier <= later }

    errors.add(:base, "membership sales must open in Core Member, Supporter, Fan, then public order")
  end

  def eligible_sales_starts(membership)
    starts = [ sales_start_at ]
    return starts unless membership

    eligible_levels = Membership::LEVELS.take(Membership::LEVELS.index(membership.level) + 1)
    starts << fan_sales_start_at if eligible_levels.include?("fan")
    starts << supporter_sales_start_at if eligible_levels.include?("supporter")
    starts << core_member_sales_start_at if eligible_levels.include?("core_member")
    starts
  end

  def quantity_covers_existing_commitments
    return unless persisted? && quantity_total.present?

    committed = ticket_orders.paid.sum(:quantity) +
                ticket_orders.pending.where("expires_at > ?", Time.current).sum(:quantity)
    return if quantity_total >= committed

    errors.add(:quantity_total, "cannot be lower than #{committed} sold or reserved tickets")
  end
end
