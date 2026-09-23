class BandPolicy < ApplicationPolicy
  def show?
    member? || user&.platform_admin?
  end

  def create?
    user.present?
  end

  # Editing a band's own profile is day-to-day band work: a platform
  # admin only reaches it by holding an administrator membership here,
  # same bar as #manage_payments? below.
  def update?
    administrator?
  end

  # The band's Stripe account is the band's own money, so only an
  # administrator of this exact band reaches it. Platform administrators
  # do not act as the band's merchant (docs/decisions.md, refunds ADR).
  def manage_payments?
    administrator?
  end

  def approve?
    user&.platform_admin?
  end

  def reject?
    user&.platform_admin?
  end

  def suspend?
    user&.platform_admin?
  end

  def reactivate?
    user&.platform_admin?
  end

  def feature?
    user&.platform_admin?
  end

  def unfeature?
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
