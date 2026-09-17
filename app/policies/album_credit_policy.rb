class AlbumCreditPolicy < ApplicationPolicy
  def create?
    member?
  end

  def destroy?
    member?
  end

  private

  def member?
    return false if user.nil?

    user.platform_admin? || record.album.band.band_memberships.exists?(user_id: user.id)
  end
end
