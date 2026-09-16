require "rails_helper"

RSpec.describe PollVote, type: :model do
  it "is valid with valid attributes" do
    expect(build(:poll_vote)).to be_valid
  end

  it "prevents the same user from voting for the same option twice" do
    option = create(:poll_option)
    user = create(:user)
    create(:poll_vote, user: user, poll_option: option)
    duplicate = build(:poll_vote, user: user, poll_option: option)

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:user_id]).to be_present
  end

  it "rejects a duplicate vote at the database level even if validation is bypassed" do
    option = create(:poll_option)
    user = create(:user)
    create(:poll_vote, user: user, poll_option: option)
    duplicate = build(:poll_vote, user: user, poll_option: option)

    expect { duplicate.save(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
  end

  it "allows the same user to vote for different options (multiple-choice polls)" do
    poll = create(:poll, :published, allow_multiple_choices: true)
    user = create(:user)
    create(:poll_vote, user: user, poll_option: poll.poll_options.first)
    create(:poll_vote, user: user, poll_option: poll.poll_options.second)

    expect(user.poll_votes.count).to eq(2)
  end
end
