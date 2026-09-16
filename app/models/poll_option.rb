class PollOption < ApplicationRecord
  belongs_to :poll
  has_many :poll_votes, dependent: :destroy
  has_many :voters, through: :poll_votes, source: :user

  validates :label, presence: true

  def votes_count
    poll_votes.count
  end
end
