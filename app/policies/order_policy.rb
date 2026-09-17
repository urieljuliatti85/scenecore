# An order is visible to the fan who placed it and to the band that has to
# fulfil it, and to nobody else — it carries a delivery address and what
# someone paid.
class OrderPolicy < ApplicationPolicy
  def show?
    placed_by_user? || administrator_of_band?
  end

  # Only the band packs and ships, so only the band moves an order along.
  def fulfil?
    administrator_of_band? && record.next_fulfilment_status.present?
  end

  private

  def placed_by_user?
    return false if user.nil?

    record.user_id == user.id
  end

  def administrator_of_band?
    return false if user.nil?

    user.platform_admin? ||
      record.band.band_memberships.exists?(user_id: user.id, role: :administrator)
  end
end
