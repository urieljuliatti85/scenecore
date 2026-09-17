# A band-configured discount percentage per membership level
# (docs/band-admin.md §18). No storefront exists yet to apply this
# against — this is the configuration a future commerce feature reads,
# not commerce itself. Values must be explicit per band rather than
# hardcoded, since bands set their own percentages.
class MerchDiscount < ApplicationRecord
  belongs_to :band

  enum :level, Membership::LEVELS.index_with(&:itself), validate: true

  validates :level, uniqueness: { scope: :band_id }
  validates :percentage, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
end
