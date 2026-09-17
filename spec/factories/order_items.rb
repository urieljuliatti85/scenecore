FactoryBot.define do
  factory :order_item do
    order
    product_variant
    product_name { "Product" }
    variant_name { "Size M" }
    unit_price_cents { 2_500 }
    quantity { 1 }
  end
end
