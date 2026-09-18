class BandAdminRequestPolicy < ApplicationPolicy
  def create?
    user.present? && record.user_id == user.id
  end

  def revoke?
    return false if user.nil?

    user.platform_admin? || record.user_id == user.id
  end

  def approve?
    user&.platform_admin? || false
  end

  def reject?
    user&.platform_admin? || false
  end
end
