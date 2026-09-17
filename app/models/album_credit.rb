# A band-controlled, opt-in credit on a specific album — the band picks
# who appears, per docs/band-admin.md §17 ("do not assume every release
# must show every member").
class AlbumCredit < ApplicationRecord
  belongs_to :album
  belongs_to :user

  validates :user_id, uniqueness: { scope: :album_id }
  validate :user_has_eligible_membership

  private

  # Supporter and above only — Fan does not include digital credits
  # (docs/memberships.md §3.2/§3.3).
  def user_has_eligible_membership
    return if album.nil? || user.nil?

    membership = album.band.memberships.find_by(user: user)
    return if membership&.can_access?(:supporter)

    errors.add(:user, "must have an active Supporter or Core Member membership with this band")
  end
end
