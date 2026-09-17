class DirectMessageThreadPolicy < ApplicationPolicy
  def show?
    band_member? || owner?
  end

  def create_message?
    return false if user.nil?

    (band_member? || (owner? && record.messageable_by_member?))
  end

  def archive?
    band_member?
  end

  def block?
    band_member?
  end

  def unblock?
    band_member?
  end

  private

  def band_member?
    return false if user.nil?

    user.platform_admin? || record.band.band_memberships.exists?(user_id: user.id)
  end

  def owner?
    user.present? && record.user_id == user.id
  end
end
