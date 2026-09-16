class UserPolicy < ApplicationPolicy
  def index?
    platform_admin?
  end

  def edit?
    platform_admin?
  end

  def update?
    platform_admin?
  end

  def destroy?
    platform_admin?
  end

  private

  def platform_admin?
    user.present? && user.platform_admin?
  end
end
