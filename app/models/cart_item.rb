class CartItem < ApplicationRecord
  belongs_to :cart
  belongs_to :product_variant

  validates :quantity, numericality: { only_integer: true, greater_than: 0 }
  validates :product_variant_id, uniqueness: { scope: :cart_id }
  validate :variant_belongs_to_cart_band

  private

  # docs/database.md CartItems: a cart item's variant must belong to the
  # same band as the cart itself — the single-band-cart invariant
  # (ADR-003) is only real if this is enforced here, not just assumed by
  # the UI that adds items.
  def variant_belongs_to_cart_band
    return if cart.nil? || product_variant.nil?

    return if product_variant.product.band_id == cart.band_id

    errors.add(:product_variant, "must belong to the cart's band")
  end
end
