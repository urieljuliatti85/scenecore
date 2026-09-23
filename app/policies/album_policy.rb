class AlbumPolicy < ApplicationPolicy
  def show?
    member?
  end

  def create?
    member?
  end

  def update?
    member?
  end

  def search?
    member?
  end

  def publish?
    member?
  end

  def unpublish?
    member?
  end

  private

  # Album unpublish has no audited platform-moderation path (only
  # Admin::AlbumsController#unpublish does — a separate action, logged
  # there), so a platform admin only reaches this policy's actions by
  # holding a membership in the band.
  def member?
    return false if user.nil?

    record.band.band_memberships.exists?(user_id: user.id)
  end
end
