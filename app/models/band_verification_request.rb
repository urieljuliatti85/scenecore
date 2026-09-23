# A Band Administrator asking a Platform Administrator to confirm an email
# address is genuinely the band's own, before the badge is granted. Two
# parties, two steps: a Platform Administrator reviews the request (outside
# SceneCore) and approves it, which emails the submitted address a one-time
# link; only opening that link sets Band#verified. The admin's review
# catches a fabricated email; the emailed link catches a real address the
# requester doesn't actually control — neither step alone would catch both
# (docs/product.md §5 Bands Acceptance Criteria, "Verified Band" badge).
#
# Mirrors BandAdminRequest's pending/approve/reject shape, with an extra
# state (email_sent) for "approved, awaiting the band's click."
class BandVerificationRequest < ApplicationRecord
  belongs_to :band

  enum :status, { pending: "pending", email_sent: "email_sent", verified: "verified", rejected: "rejected" },
       default: :pending, validate: true

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :band_id, uniqueness: { conditions: -> { where(status: %w[pending email_sent]) }, message: "already has an open verification request" },
            if: -> { pending? || email_sent? }

  generates_token_for :band_verification, expires_in: 3.days

  # The one place Band#verified is set true: only by a request completing
  # its own click-through, never directly.
  def verify!
    transaction do
      update!(status: :verified)
      band.update!(verified: true)
    end
  end
end
