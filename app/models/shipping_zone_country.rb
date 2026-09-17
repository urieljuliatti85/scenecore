# One country inside a band's shipping zone. `band_id` is denormalised from
# the zone so the database can enforce "a band lists a country at most
# once" with a unique index — without it, two zones of the same band could
# each claim BR and the rate for Brazil would depend on join order.
class ShippingZoneCountry < ApplicationRecord
  belongs_to :shipping_zone
  belongs_to :band

  validates :country_code, presence: true,
                           uniqueness: { scope: :band_id, message: "is already in another zone" }
  validate :country_code_recognised

  before_validation :normalize_country_code
  before_validation :inherit_band_from_zone

  def country_name
    Country.name_for(country_code) || country_code
  end

  private

  def normalize_country_code
    self.country_code = Country.normalize(country_code) if country_code.present?
  end

  def inherit_band_from_zone
    self.band_id ||= shipping_zone&.band_id
  end

  def country_code_recognised
    return if country_code.blank?

    errors.add(:country_code, "is not a recognised country") unless Country.valid?(country_code)
  end
end
