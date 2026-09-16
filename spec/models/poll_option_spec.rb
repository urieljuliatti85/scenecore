require "rails_helper"

RSpec.describe PollOption, type: :model do
  it "is valid with valid attributes" do
    expect(build(:poll_option)).to be_valid
  end

  it "requires a label" do
    option = build(:poll_option, label: nil)

    expect(option).not_to be_valid
  end

  describe "#votes_count" do
    it "counts the votes for this option" do
      option = create(:poll_option)
      create(:poll_vote, poll_option: option)
      create(:poll_vote, poll_option: option)

      expect(option.votes_count).to eq(2)
    end

    it "is zero when no one has voted" do
      option = create(:poll_option)

      expect(option.votes_count).to eq(0)
    end
  end
end
