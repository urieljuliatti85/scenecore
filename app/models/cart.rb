# A fan's in-progress selection of one band's product variants prior to
# checkout (docs/database.md Carts). At most one active cart exists per
# user platform-wide, enforced by a partial unique index on
# carts.user_id — see the create_carts migration, not just this model.
class Cart < ApplicationRecord
  belongs_to :user
  belongs_to :band
  has_many :cart_items, dependent: :destroy

  enum :status, { active: "active", converted: "converted", abandoned: "abandoned" },
       default: :active, validate: true

  def subtotal_cents
    cart_items.sum { |item| item.quantity * item.product_variant.price_cents }
  end

  # Charged once per distinct product, not per unit — two copies of the same
  # record ship together.
  #
  # The rate depends on where the parcel is going, so this needs the
  # destination and returns nil when the band ships to none of it: a cart
  # whose total cannot be computed must not be checked out at a guessed
  # price. The cart page, which has no address yet, shows a range instead
  # (#shipping_cents_range).
  def shipping_cents_for(country_code)
    return nil if country_code.blank?

    rates = distinct_products.map { |product| product.shipping_cents_for(country_code) }
    return nil if rates.any?(&:nil?)

    rates.sum
  end

  def total_cents_for(country_code)
    shipping = shipping_cents_for(country_code)
    return nil if shipping.nil?

    subtotal_cents + shipping
  end

  # What the fan might pay to ship, across every destination the band
  # serves, as [ lowest, highest ]. The cart page has no address yet, so it
  # can only show a range; a band charging one flat rate everywhere gets a
  # pair of equal numbers, which the view renders as a single figure.
  def shipping_cents_range
    zones = band.shipping_zones.includes(:zone_countries).ordered
    return [ flat_shipping_cents, flat_shipping_cents ] if zones.empty?

    totals = zones.filter_map do |zone|
      country = zone.zone_countries.first&.country_code
      shipping_cents_for(country) if country
    end

    totals.empty? ? nil : [ totals.min, totals.max ]
  end

  # The pre-zones figure: the sum of each product's own flat rate, used
  # while the band has configured no zones (see Product#shipping_cents_for).
  def flat_shipping_cents
    distinct_products.sum(&:shipping_cents)
  end

  def distinct_products
    cart_items.map { |item| item.product_variant.product }.uniq
  end
end
