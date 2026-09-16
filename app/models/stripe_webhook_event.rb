class StripeWebhookEvent < ApplicationRecord
  DuplicateEvent = Class.new(StandardError)

  validates :stripe_event_id, presence: true, uniqueness: true
  validates :event_type, presence: true

  def self.record!(stripe_event_id:, event_type:)
    create!(stripe_event_id: stripe_event_id, event_type: event_type, processed_at: Time.current)
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
    raise DuplicateEvent, "Stripe event #{stripe_event_id} was already processed"
  end
end
