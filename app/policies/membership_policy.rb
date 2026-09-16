class MembershipPolicy < ApplicationPolicy
  def show?
    owner? || administrator_of_band? || user&.platform_admin?
  end

  def index?
    administrator_of_band? || user&.platform_admin?
  end

  def create?
    administrator_of_band?
  end

  def update?
    administrator_of_band? || user&.platform_admin?
  end

  def destroy?
    administrator_of_band? || user&.platform_admin?
  end

  def moderate?
    administrator_of_band? || user&.platform_admin?
  end
  alias_method :pause?, :moderate?
  alias_method :reactivate?, :moderate?

  def cancel?
    owner? || moderate?
  end

  class Scope < Scope
    def resolve
      return scope.none if user.nil?
      return scope.all if user.platform_admin?

      administered_band_ids = user.band_memberships.administrator.pluck(:band_id)
      scope.where(user_id: user.id).or(scope.where(band_id: administered_band_ids))
    end
  end

  private

  def owner?
    user.present? && record.user_id == user.id
  end

  def administrator_of_band?
    return false if user.nil?

    record.band.band_memberships.exists?(user_id: user.id, role: :administrator)
  end
end
