class BandPolicy < ApplicationPolicy
  def show?
    member? || user&.platform_admin?
  end

  def create?
    user.present?
  end

  def update?
    administrator?
  end

  def approve?
    user&.platform_admin?
  end

  def reject?
    user&.platform_admin?
  end

  class Scope < Scope
    def resolve
      return scope.none if user.nil?
      return scope.all if user.platform_admin?

      scope.joins(:band_memberships).where(band_memberships: { user_id: user.id }).distinct
    end
  end

  private

  def membership
    @membership ||= record.band_memberships.find_by(user_id: user&.id)
  end

  def member?
    membership.present?
  end

  def administrator?
    membership&.administrator? || false
  end
end
