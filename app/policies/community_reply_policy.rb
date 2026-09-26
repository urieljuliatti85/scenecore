class CommunityReplyPolicy < ApplicationPolicy
  def create?
    CommunityTopicPolicy.new(user, record.community_topic).show?
  end

  def destroy?
    return false if user.nil?

    record.user_id == user.id || moderator?
  end

  private

  def moderator?
    user.platform_admin? || record.band.band_memberships.administrator.exists?(user_id: user.id)
  end
end
