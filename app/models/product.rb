class Product < ApplicationRecord
  include HasImage

  has_image :image

  belongs_to :band
  has_many :variants, class_name: "ProductVariant", dependent: :destroy
  has_many :shipping_rates, class_name: "ProductShippingRate", dependent: :destroy

  accepts_nested_attributes_for :variants
  accepts_nested_attributes_for :shipping_rates, allow_destroy: true

  enum :status, { draft: "draft", published: "published" }, default: :draft, validate: true
  enum :source, { manual: "manual", discogs: "discogs" }, default: :manual, validate: true

  validates :name, presence: true
  validates :shipping_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :discogs_release_id, uniqueness: { scope: :band_id }, allow_nil: true
  validates :discogs_release_id, presence: true, if: :discogs?

  scope :published, -> { where(status: :published) }

  # What it costs to ship this product to a country, or nil when the band
  # does not ship there at all. nil is the caller's signal to refuse the
  # destination rather than to charge nothing.
  #
  # A band with no zones yet keeps selling at its flat per-product rate.
  # Zones were added after bands were already listing products, and
  # treating "not configured" as "ships nowhere" would have closed those
  # stores on deploy. Once a band defines its first zone the zones decide,
  # including for countries it chose to leave out.
  def shipping_cents_for(country_code)
    return shipping_cents unless band.shipping_zones.exists?

    zone = band.shipping_zones.serving(country_code).first
    return nil if zone.nil?

    override = shipping_rates.find { |rate| rate.shipping_zone_id == zone.id }
    override&.shipping_cents || zone.shipping_cents
  end

  # The rate shown on the product form as the default for new zones, and
  # the rate used while the band has defined none.
  def ships_by_zone?
    band.shipping_zones.exists?
  end

  def discogs_url
    return if discogs_release_id.blank?

    "https://www.discogs.com/release/#{discogs_release_id}"
  end
end
