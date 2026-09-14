class FollowPolicy < ApplicationPolicy
  def create?
    user.present? && record.band.approved?
  end

  def destroy?
    user.present? && record.user_id == user.id
  end
end
