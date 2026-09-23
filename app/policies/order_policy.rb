# An order is visible to the fan who placed it and to the band that has to
# fulfil it, and to nobody else — it carries a delivery address and what
# someone paid.
class OrderPolicy < ApplicationPolicy
  def show?
    placed_by_user? || administrator_of_band?
  end

  # Only the band packs and ships, so only the band moves an order along —
  # same bar as #refund?, no platform-admin bypass.
  def fulfil?
    band_administrator? && record.next_fulfilment_status.present?
  end

  # Money is returned on the band's behalf, so only an administrator of
  # this exact band can request it. Platform administrators can inspect
  # orders but do not act as the band's merchant here.
  def refund?
    band_administrator? && record.refundable?
  end

  private

  def placed_by_user?
    return false if user.nil?

    record.user_id == user.id
  end

  def administrator_of_band?
    return false if user.nil?

    user.platform_admin? || band_administrator?
  end

  def band_administrator?
    return false if user.nil?

    record.band.band_memberships.exists?(user_id: user.id, role: :administrator)
  end
end
