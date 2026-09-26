class CommunityTopicPolicy < ApplicationPolicy
  def index?
    participant?
  end

  def show?
    participant?
  end

  def create?
    participant?
  end

  def destroy?
    return false if user.nil?

    record.user_id == user.id || moderator?
  end

  private

  def band
    record.band
  end

  def participant?
    return false if user.nil?
    return true if user.platform_admin?
    return true if band.band_memberships.exists?(user_id: user.id)

    band.memberships.active.exists?(user_id: user.id)
  end

  def moderator?
    user.platform_admin? || band.band_memberships.administrator.exists?(user_id: user.id)
  end
end
