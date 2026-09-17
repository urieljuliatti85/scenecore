class ShippingAddress < ApplicationRecord
  belongs_to :order

  validates :recipient_name, :line1, :city, :state, :postal_code, :country, presence: true
  validate :country_recognised

  before_validation :normalize_country

  def country_name
    Country.name_for(country) || country
  end

  private

  # The column holds an ISO-3166-1 alpha-2 code so a destination can be
  # matched against a band's shipping zones by equality. Addresses created
  # before the country field became a select may hold a free-text name; the
  # validation only runs on the records this app writes from now on, and
  # #country_name falls back to whatever is stored.
  def normalize_country
    self.country = Country.normalize(country) if country.present?
  end

  def country_recognised
    return if country.blank?

    errors.add(:country, "is not a recognised country") unless Country.valid?(country)
  end
end
