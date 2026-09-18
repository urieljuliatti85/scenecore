# A user asking a Platform Administrator to be let in and made an
# administrator of a band (docs/proposals/band-admin-promotion-request.md)
# — typically someone with no existing tie to the band on SceneCore yet.
# Mirrors Report's shape: a user-initiated escalation the platform
# decides on, not something the band itself arbitrates.
class BandAdminRequest < ApplicationRecord
  belongs_to :user
  belongs_to :band

  enum :status, { pending: "pending", approved: "approved", rejected: "rejected", revoked: "revoked" },
       default: :pending, validate: true

  validates :user_id, uniqueness: { scope: :band_id, conditions: -> { pending }, message: "already has a pending request for this band" },
            if: :pending?
end
