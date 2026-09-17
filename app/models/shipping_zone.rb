# A destination a band is willing to ship to, with the flat rate it charges
# to send one item there.
#
# Bands define their own zones rather than choosing from platform-wide
# regions (docs/product.md §7). That is the Discogs model: a seller lists
# the destinations it actually serves, and a country nobody listed simply
# cannot be shipped to. The consequence to keep in mind is that an absent
# country is a refusal, not a default — nothing silently falls back to a
# platform rate.
class ShippingZone < ApplicationRecord
  belongs_to :band
  has_many :zone_countries, class_name: "ShippingZoneCountry", dependent: :destroy
  has_many :product_shipping_rates, dependent: :destroy

  accepts_nested_attributes_for :zone_countries, allow_destroy: true

  validates :name, presence: true, uniqueness: { scope: :band_id, case_sensitive: false }
  validates :shipping_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :ordered, -> { order(:position, :name) }

  # The zone serving a country, or nil when the band does not ship there.
  scope :serving, lambda { |country_code|
    joins(:zone_countries)
      .where(shipping_zone_countries: { country_code: Country.normalize(country_code) })
  }

  def country_codes
    zone_countries.map(&:country_code)
  end

  def country_names
    country_codes.map { |code| Country.name_for(code) || code }.sort
  end
end
