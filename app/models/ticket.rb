class Ticket < ApplicationRecord
  belongs_to :ticket_order
  belongs_to :event
  belongs_to :user
  belongs_to :checked_in_by, class_name: "User", optional: true,
             inverse_of: :checked_in_tickets

  before_validation :assign_public_token, on: :create

  validates :public_token, presence: true, uniqueness: true
  validate :order_matches_event_and_user
  validate :check_in_fields_are_paired

  def used?
    used_at.present?
  end

  private

  def assign_public_token
    self.public_token ||= SecureRandom.urlsafe_base64(32)
  end

  def order_matches_event_and_user
    return if ticket_order.blank?

    errors.add(:event, "must match the ticket order") if event != ticket_order.event
    errors.add(:user, "must match the ticket order purchaser") if user != ticket_order.user
  end

  def check_in_fields_are_paired
    return if used_at.present? == checked_in_by.present?

    errors.add(:base, "check-in time and validator must be recorded together")
  end
end
