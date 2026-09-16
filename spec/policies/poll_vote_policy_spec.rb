require "rails_helper"

RSpec.describe PollVotePolicy do
  subject { described_class.new(user, poll) }

  describe "#upsert?" do
    context "when the poll is open and publicly visible" do
      let(:poll) { create(:poll, :published) }
      let(:user) { create(:user) }

      it { is_expected.to be_upsert }
    end

    context "when the poll is still a draft" do
      let(:poll) { create(:poll) }
      let(:user) { create(:user) }

      it { is_expected.not_to be_upsert }
    end

    context "when the poll requires a membership level the user lacks" do
      let(:band) { create(:band) }
      let(:poll) { create(:poll, :published, :fan_only, band: band) }
      let(:user) { create(:user) }

      it { is_expected.not_to be_upsert }
    end

    context "when the user has the required membership level" do
      let(:band) { create(:band) }
      let(:poll) { create(:poll, :published, :fan_only, band: band) }
      let(:user) { create(:user) }
      before { create(:membership, band: band, user: user, level: :fan) }

      it { is_expected.to be_upsert }
    end

    context "when the user is anonymous" do
      let(:poll) { create(:poll, :published) }
      let(:user) { nil }

      it { is_expected.not_to be_upsert }
    end
  end
end
