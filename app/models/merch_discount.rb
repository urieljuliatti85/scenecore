# A band-configured discount percentage per membership level
# (docs/band-admin.md §18). Values are explicit per band rather than
# hardcoded, and Cart reads them to price a Store order.
class MerchDiscount < ApplicationRecord
  belongs_to :band

  enum :level, Membership::LEVELS.index_with(&:itself), validate: true

  validates :level, uniqueness: { scope: :band_id }
  validates :percentage, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }

  # A level's discounts are cumulative just like its content benefits. For
  # example, a Core Member receives a Supporter discount when the band has
  # not configured a separate Core percentage yet. Choosing the highest
  # configured eligible percentage prevents a lower tier from accidentally
  # becoming the better offer.
  def self.percentage_for(membership)
    return 0 unless membership&.grants_access?

    eligible_levels = Membership::LEVELS.take(Membership::LEVELS.index(membership.level) + 1)
    membership.band.merch_discounts.where(level: eligible_levels).maximum(:percentage) || 0
  end
end
