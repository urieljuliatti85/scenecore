class ReportPolicy < ApplicationPolicy
  def create?
    return false if user.nil?

    case record.reportable
    when Post
      record.reportable.visible_to?(user)
    when Comment
      record.reportable.post.visible_to?(user)
    when CommunityTopic
      CommunityTopicPolicy.new(user, record.reportable).show?
    when CommunityReply
      CommunityTopicPolicy.new(user, record.reportable.community_topic).show?
    else
      false
    end
  end
end
