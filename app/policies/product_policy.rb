class ProductPolicy < ApplicationPolicy
  def index?
    administrator_of_band?
  end

  def show?
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

  def publish?
    administrator_of_band?
  end

  def unpublish?
    administrator_of_band?
  end

  private

  def band
    record.is_a?(Product) ? record.band : record
  end

  def administrator_of_band?
    return false if user.nil?

    user.platform_admin? || band.band_memberships.exists?(user_id: user.id, role: :administrator)
  end
end
