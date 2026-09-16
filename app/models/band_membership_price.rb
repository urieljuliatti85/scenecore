class BandMembershipPrice < ApplicationRecord
  belongs_to :band

  enum :level, Membership::LEVELS.index_with(&:itself), validate: true

  validates :band_id, uniqueness: { scope: :level }
  validates :stripe_product_id, presence: true
  validates :stripe_price_id, presence: true
end
