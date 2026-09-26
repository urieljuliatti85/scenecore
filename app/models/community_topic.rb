class CommunityTopic < ApplicationRecord
  belongs_to :band
  belongs_to :user
  has_many :community_replies, -> { order(:created_at) }, dependent: :destroy
  has_many :reports, as: :reportable, dependent: :destroy

  validates :title, :body, presence: true
end
