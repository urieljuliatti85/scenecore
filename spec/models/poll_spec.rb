require "rails_helper"

RSpec.describe Poll, type: :model do
  it "is valid with valid attributes" do
    expect(build(:poll)).to be_valid
  end

  it "requires a question" do
    poll = build(:poll, question: nil)

    expect(poll).not_to be_valid
  end

  it "requires at least two options" do
    poll = build(:poll)
    poll.poll_options = [ build(:poll_option, poll: nil, label: "Only one") ]

    expect(poll).not_to be_valid
    expect(poll.errors[:base]).to include("must have at least two options")
  end

  it "defaults status to draft" do
    expect(create(:poll).status).to eq("draft")
  end

  it "restricts status to draft or published" do
    poll = build(:poll)
    poll.status = "archived"

    expect(poll).not_to be_valid
  end

  it "restricts visibility to public, followers, fan, supporter, or core_member" do
    poll = build(:poll)
    poll.visibility = "everyone"

    expect(poll).not_to be_valid
  end

  describe "#open?" do
    it "is false when draft" do
      poll = create(:poll)

      expect(poll.open?).to be false
    end

    it "is true when published with no time window" do
      poll = create(:poll, :published)

      expect(poll.open?).to be true
    end

    it "is false before opens_at" do
      poll = create(:poll, :published, opens_at: 1.hour.from_now)

      expect(poll.open?).to be false
    end

    it "is false after closes_at" do
      poll = create(:poll, :published, closes_at: 1.hour.ago)

      expect(poll.open?).to be false
    end

    it "is true within the opens_at/closes_at window" do
      poll = create(:poll, :published, opens_at: 1.hour.ago, closes_at: 1.hour.from_now)

      expect(poll.open?).to be true
    end
  end

  describe "#voteable_by?" do
    it "is true for an open, publicly visible poll" do
      poll = create(:poll, :published)
      user = create(:user)

      expect(poll.voteable_by?(user)).to be true
    end

    it "is false for a draft poll even if otherwise visible" do
      poll = create(:poll)
      user = create(:user)

      expect(poll.voteable_by?(user)).to be false
    end

    it "is false when the visibility level is not met" do
      poll = create(:poll, :published, :fan_only)
      user = create(:user)

      expect(poll.voteable_by?(user)).to be false
    end

    it "is true when the user has the required membership level" do
      band = create(:band)
      poll = create(:poll, :published, :fan_only, band: band)
      user = create(:user)
      create(:membership, band: band, user: user, level: :fan)

      expect(poll.voteable_by?(user)).to be true
    end
  end

  describe "#voted_by?" do
    it "is false when the user has not voted" do
      poll = create(:poll, :published)
      user = create(:user)

      expect(poll.voted_by?(user)).to be false
    end

    it "is true when the user has voted for one of the poll's options" do
      poll = create(:poll, :published)
      user = create(:user)
      create(:poll_vote, user: user, poll_option: poll.poll_options.first)

      expect(poll.voted_by?(user)).to be true
    end

    it "is false for an anonymous user" do
      poll = create(:poll, :published)

      expect(poll.voted_by?(nil)).to be false
    end

    it "does not count a vote on a different poll's option" do
      poll = create(:poll, :published)
      other_poll = create(:poll, :published)
      user = create(:user)
      create(:poll_vote, user: user, poll_option: other_poll.poll_options.first)

      expect(poll.voted_by?(user)).to be false
    end
  end
end
