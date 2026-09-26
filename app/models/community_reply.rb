class CommunityReply < ApplicationRecord
  belongs_to :community_topic, touch: true
  belongs_to :user
  has_many :reports, as: :reportable, dependent: :destroy

  validates :body, presence: true

  delegate :band, to: :community_topic
end
