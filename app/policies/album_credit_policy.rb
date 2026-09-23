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

    record.album.band.band_memberships.exists?(user_id: user.id)
  end
end
