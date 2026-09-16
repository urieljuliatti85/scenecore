class SubscriptionPolicy < ApplicationPolicy
  def join?
    user.present? && record.band.approved? && (record.new_record? || owner?)
  end

  private

  def owner?
    user.present? && record.user_id == user.id
  end
end
