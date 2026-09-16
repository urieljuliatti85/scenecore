class CommentPolicy < ApplicationPolicy
  def create?
    user.present? && record.post.visible_to?(user)
  end

  def destroy?
    return false if user.nil?

    author? || band_member? || user.platform_admin?
  end

  private

  def author?
    record.user_id == user.id
  end

  def band_member?
    record.post.band.band_memberships.exists?(user_id: user.id)
  end
end
