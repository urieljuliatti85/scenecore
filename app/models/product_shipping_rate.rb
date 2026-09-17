# A product's own rate for one of its band's zones, overriding the zone's
# figure. A record exists only where the band set an override, so the
# absence of one means "charge the zone rate" — distinct from an override
# of 0, which is deliberate free shipping for that item.
class ProductShippingRate < ApplicationRecord
  belongs_to :product
  belongs_to :shipping_zone

  validates :shipping_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :shipping_zone_id, uniqueness: { scope: :product_id }
  validate :zone_belongs_to_product_band

  private

  def zone_belongs_to_product_band
    return if product.nil? || shipping_zone.nil?
    return if product.band_id == shipping_zone.band_id

    errors.add(:shipping_zone, "must belong to the same band as the product")
  end
end
