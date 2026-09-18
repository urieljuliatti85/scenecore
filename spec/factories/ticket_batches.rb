FactoryBot.define do
  factory :ticket_batch do
    event { association :event, :published }
    sequence(:name) { |n| "General admission #{n}" }
    price_cents { 2_500 }
    quantity_total { 100 }
  end
end
