class CoreSessionRsvp < ApplicationRecord
  belongs_to :core_session
  belongs_to :user

  validates :user_id, uniqueness: { scope: :core_session_id }
  validate :user_has_eligible_membership
  validate :seats_available, on: :create

  private

  def user_has_eligible_membership
    return if core_session.nil? || user.nil?

    membership = core_session.band.memberships.find_by(user: user)
    return if membership&.can_access?(core_session.audience_level)

    errors.add(:user, "must have an active #{core_session.audience_level.humanize} membership with this band")
  end

  def seats_available
    return if core_session.nil?

    errors.add(:base, "This session is fully booked") unless core_session.seats_available?
  end
end
