class CoreSessionPolicy < ApplicationPolicy
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
    member?
  end

  def publish?
    member?
  end

  def unpublish?
    member?
  end

  private

  # This band's own membership work: none of these actions has an
  # audited platform-moderation path (unlike posts/comments/DM threads),
  # so a platform admin only reaches them by holding a membership here.
  def member?
    return false if user.nil?

    record.band.band_memberships.exists?(user_id: user.id)
  end
end
