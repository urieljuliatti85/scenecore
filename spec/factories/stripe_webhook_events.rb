FactoryBot.define do
  factory :stripe_webhook_event do
    sequence(:stripe_event_id) { |n| "evt_test#{n}" }
    event_type { "checkout.session.completed" }
    processed_at { Time.current }
  end
end
