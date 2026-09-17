class ProductVariantPolicy < ApplicationPolicy
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

  def administrator_of_band?
    return false if user.nil?

    band = record.product.band
    user.platform_admin? || band.band_memberships.exists?(user_id: user.id, role: :administrator)
  end
end
