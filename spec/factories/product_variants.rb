FactoryBot.define do
  factory :product_variant do
    product
    sequence(:sku) { |n| "SKU-#{n}" }
    sequence(:name) { |n| "Size #{n}" }
    price_cents { 2_500 }
    stock_quantity { 10 }

    trait :sold_out do
      stock_quantity { 0 }
    end
  end
end
