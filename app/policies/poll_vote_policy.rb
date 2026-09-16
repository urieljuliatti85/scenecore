class PollVotePolicy < ApplicationPolicy
  def upsert?
    record.voteable_by?(user)
  end
end
