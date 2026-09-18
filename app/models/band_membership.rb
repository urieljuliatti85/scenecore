class BandMembership < ApplicationRecord
  belongs_to :user
  belongs_to :band
  has_many :band_admin_requests, dependent: :destroy

  enum :role, { member: "member", administrator: "administrator" },
       default: :member, validate: true

  validates :user_id, uniqueness: { scope: :band_id, message: "is already a member of this band" }

  before_destroy :ensure_not_last_administrator
  before_update :ensure_not_demoting_last_administrator, if: :role_changed?

  private

  def ensure_not_last_administrator
    return unless administrator?
    return unless band.band_memberships.administrator.where.not(id: id).none?

    errors.add(:base, "cannot remove the last administrator of a band")
    throw :abort
  end

  def ensure_not_demoting_last_administrator
    return unless role_was == "administrator" && !administrator?
    return unless band.band_memberships.administrator.where.not(id: id).none?

    errors.add(:base, "cannot demote the last administrator of a band")
    throw :abort
  end
end
