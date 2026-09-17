class ReportPolicy < ApplicationPolicy
  def create?
    return false if user.nil?

    case record.reportable
    when Post
      record.reportable.visible_to?(user)
    when Comment
      record.reportable.post.visible_to?(user)
    else
      false
    end
  end
end
