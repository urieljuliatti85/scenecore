FactoryBot.define do
  factory :order do
    user
    band
    status { :pending }
    subtotal_cents { 2_500 }
    shipping_cents { 0 }
    total_cents { 2_500 }
    platform_fee_cents { 250 }

    trait :paid do
      status { :paid }
    end
  end
end
