class BandVerificationRequestPolicy < ApplicationPolicy
  def create?
    return false if user.nil?

    band.band_memberships.exists?(user_id: user.id, role: :administrator)
  end

  def approve?
    user&.platform_admin? || false
  end

  def reject?
    user&.platform_admin? || false
  end

  def resend?
    user&.platform_admin? || false
  end

  private

  def band
    record.is_a?(BandVerificationRequest) ? record.band : record
  end
end
