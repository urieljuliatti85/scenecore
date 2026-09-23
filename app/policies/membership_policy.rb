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

  # The band's own panel (MembershipsController): managing a fan's
  # membership there is day-to-day band work, not the platform-moderation
  # path Admin::MembershipsController offers through #update?/#destroy?/
  # #moderate? above — so no platform-admin bypass here.
  def manage_supporters?
    administrator_of_band?
  end
  alias_method :create_from_band_panel?, :manage_supporters?
  alias_method :update_from_band_panel?, :manage_supporters?
  alias_method :destroy_from_band_panel?, :manage_supporters?

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
