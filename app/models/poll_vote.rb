class PollVote < ApplicationRecord
  belongs_to :user
  belongs_to :poll_option

  validates :user_id, uniqueness: { scope: :poll_option_id }
end
