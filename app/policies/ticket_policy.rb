class TicketPolicy < ApplicationPolicy
  def show?
    owner?
  end

  def check_in?
    return false if user.nil?

    record.event.band.band_memberships.exists?(user_id: user.id)
  end

  private

  def owner?
    user.present? && record.user_id == user.id
  end
end
