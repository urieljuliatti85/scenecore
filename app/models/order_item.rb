# A frozen snapshot of one cart item at the moment its order was placed
# (docs/database.md OrderItems). product_name/variant_name/
# unit_price_cents are never recomputed from the live ProductVariant —
# product_variant_id is kept only for traceability.
class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :product_variant, optional: true

  validates :product_name, :variant_name, presence: true
  validates :unit_price_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :quantity, numericality: { only_integer: true, greater_than: 0 }
end
