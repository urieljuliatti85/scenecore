class TicketBatchPolicy < ApplicationPolicy
  def create?
    administrator?
  end

  def update?
    administrator?
  end

  def destroy?
    administrator?
  end

  private

  def administrator?
    return false if user.nil?

    record.event.band.band_memberships.administrator.exists?(user_id: user.id)
  end
end
