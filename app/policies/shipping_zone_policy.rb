# Where a band ships and what it charges is band-administrator work, the
# same bar as the products those rates apply to (docs/permissions.md).
class ShippingZonePolicy < ApplicationPolicy
  def index?
    administrator_of_band?
  end

  def create?
    administrator_of_band?
  end

  def update?
    administrator_of_band?
  end

  def destroy?
    administrator_of_band?
  end

  private

  def band
    record.is_a?(ShippingZone) ? record.band : record
  end

  def administrator_of_band?
    return false if user.nil?

    band.band_memberships.exists?(user_id: user.id, role: :administrator)
  end
end
