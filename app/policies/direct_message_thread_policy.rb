class DirectMessageThreadPolicy < ApplicationPolicy
  # Read access stays with the platform admin even without a membership:
  # triaging a report means being able to open the thread it names.
  def show?
    band_member? || owner? || user&.platform_admin?
  end

  def create_message?
    return false if user.nil?

    (band_member? || (owner? && record.messageable_by_member?))
  end

  def archive?
    band_member?
  end

  # The audited platform-moderation path (logged by the controller's
  # log_platform_moderation, docs/community.md §11): blocking a fan who is
  # abusing a band's DMs.
  def block?
    band_member? || user&.platform_admin?
  end

  def unblock?
    band_member?
  end

  private

  def band_member?
    return false if user.nil?

    record.band.band_memberships.exists?(user_id: user.id)
  end

  def owner?
    user.present? && record.user_id == user.id
  end
end
