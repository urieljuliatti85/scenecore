class PostPolicy < ApplicationPolicy
  def show?
    member?
  end

  def create?
    member?
  end

  def update?
    member?
  end

  def destroy?
    moderator?
  end

  def publish?
    member?
  end

  def unpublish?
    moderator?
  end

  private

  # Creating, editing, and publishing is day-to-day band work: a platform
  # admin only reaches it by holding a membership in this band.
  def member?
    return false if user.nil?

    record.band.band_memberships.exists?(user_id: user.id)
  end

  # Deleting or unpublishing is the platform-moderation path (logged by
  # the controller's log_platform_moderation, docs/community.md §11), so
  # it keeps reaching every band.
  def moderator?
    return false if user.nil?

    user.platform_admin? || member?
  end
end
