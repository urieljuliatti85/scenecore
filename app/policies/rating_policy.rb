class RatingPolicy < ApplicationPolicy
  def upsert?
    user.present? && record.album.published?
  end
end
