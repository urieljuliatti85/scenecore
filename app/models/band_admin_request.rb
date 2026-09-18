# A Band Member asking a Platform Administrator to promote their own
# BandMembership to administrator (docs/proposals/band-admin-promotion-request.md).
# Mirrors Report's shape: a member-initiated escalation the platform
# decides on, not something the band itself arbitrates.
class BandAdminRequest < ApplicationRecord
  belongs_to :band_membership

  enum :status, { pending: "pending", approved: "approved", rejected: "rejected", revoked: "revoked" },
       default: :pending, validate: true

  validate :band_membership_is_a_member, on: :create
  validates :band_membership_id, uniqueness: { conditions: -> { pending }, message: "already has a pending request" },
            if: :pending?

  private

  # An existing administrator has no reason to request what they already
  # have, and approving one would be a no-op that still fires the
  # "you've been promoted" email.
  def band_membership_is_a_member
    return if band_membership.nil? || band_membership.member?

    errors.add(:band_membership, "must be a Band Member to request administrator access")
  end
end
