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

  def member?
    return false if user.nil?

    user.platform_admin? || record.band.band_memberships.exists?(user_id: user.id)
  end
end
