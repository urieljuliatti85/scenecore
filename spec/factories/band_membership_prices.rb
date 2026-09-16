FactoryBot.define do
  factory :band_membership_price do
    band
    level { :fan }
    sequence(:stripe_product_id) { |n| "prod_test#{n}" }
    sequence(:stripe_price_id) { |n| "price_test#{n}" }
  end
end
