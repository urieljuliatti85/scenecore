class Membership < ApplicationRecord
  LEVELS = %w[fan supporter core_member].freeze

  belongs_to :user
  belongs_to :band

  enum :level, LEVELS.index_with(&:itself), default: :fan, validate: true
  enum :status, { active: "active", paused: "paused", cancelled: "cancelled", expired: "expired" },
       default: :active, validate: true

  validates :user_id, uniqueness: { scope: :band_id, message: "already has a membership with this band" }

  def at_least?(minimum_level)
    LEVELS.index(level) >= LEVELS.index(minimum_level.to_s)
  end

  def grants_access?
    active?
  end

  def can_access?(minimum_level)
    grants_access? && at_least?(minimum_level)
  end
end
