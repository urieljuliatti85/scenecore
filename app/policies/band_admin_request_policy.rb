class BandAdminRequestPolicy < ApplicationPolicy
  def create?
    return false if user.nil?

    record.band_membership.user_id == user.id && record.band_membership.member?
  end

  def revoke?
    return false if user.nil?

    user.platform_admin? || record.band_membership.user_id == user.id
  end

  def approve?
    user&.platform_admin? || false
  end

  def reject?
    user&.platform_admin? || false
  end
end
