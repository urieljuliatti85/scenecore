FactoryBot.define do
  factory :cart_item do
    cart
    # Default to a variant of the cart's own band so the single-band
    # invariant (ADR-003) holds without every caller wiring it up.
    product_variant { association :product_variant, product: association(:product, band: cart.band) }
    quantity { 1 }
  end
end
