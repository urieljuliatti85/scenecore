class Follow < ApplicationRecord
  belongs_to :user
  belongs_to :band

  validates :user_id, uniqueness: { scope: :band_id }
end
