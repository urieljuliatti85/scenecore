FactoryBot.define do
  factory :ticket_order do
    ticket_batch
    user
    quantity { 1 }
    unit_price_cents { ticket_batch.price_cents }
    total_cents { unit_price_cents * quantity }
    platform_fee_cents { (total_cents * 0.10).round }
    status { :pending }
    expires_at { 30.minutes.from_now }

    trait :paid do
      status { :paid }
      paid_at { Time.current }
    end
  end
end
