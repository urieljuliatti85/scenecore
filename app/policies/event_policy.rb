class EventPolicy < ApplicationPolicy
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

  def member?
    record.band.band_memberships.exists?(user_id: user&.id)
  end
end
