# Global, platform-wide configuration for the SceneCore Administrator
# (docs/band-admin.md §23's "Platform Settings" nav item — the doc names
# it but specifies nothing further, so this covers only what was
# explicitly requested: fee, legal/contact links, notification sender,
# and whether new bands can sign up).
#
# Singleton: exactly one row, fetched/created via .current rather than
# looked up by id, since there's nothing to key it on — it's not
# per-band or per-user.
class PlatformSetting < ApplicationRecord
  # Two rates rather than one: memberships carry 15% (ADR-008) and the
  # Store 10% (ADR-007), because the platform hosts and serves a membership
  # every month rather than settling a one-off sale.
  validates :membership_fee_percentage, :store_fee_percentage,
            numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validates :support_email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :notification_sender_email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true

  def self.current
    first_or_create!
  end
end
