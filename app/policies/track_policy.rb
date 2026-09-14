class TrackPolicy < ApplicationPolicy
  def create?
    member?
  end

  def update?
    member?
  end

  private

  def member?
    record.band.band_memberships.exists?(user_id: user&.id)
  end
end
