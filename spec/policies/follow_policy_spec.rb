require "rails_helper"

RSpec.describe FollowPolicy do
  subject { described_class.new(user, follow) }

  describe "#create?" do
    let(:band) { create(:band, :approved) }
    let(:follow) { build(:follow, band: band) }

    context "when user is authenticated and the band is approved" do
      let(:user) { create(:user) }

      it { is_expected.to be_create }
    end

    context "when user is anonymous" do
      let(:user) { nil }

      it { is_expected.not_to be_create }
    end

    context "when the band is not approved" do
      let(:band) { create(:band) }
      let(:user) { create(:user) }

      it { is_expected.not_to be_create }
    end
  end

  describe "#destroy?" do
    let(:band) { create(:band, :approved) }
    let(:owner) { create(:user) }
    let(:follow) { create(:follow, band: band, user: owner) }

    context "when user owns the follow" do
      let(:user) { owner }

      it { is_expected.to be_destroy }
    end

    context "when user does not own the follow" do
      let(:user) { create(:user) }

      it { is_expected.not_to be_destroy }
    end

    context "when user is anonymous" do
      let(:user) { nil }

      it { is_expected.not_to be_destroy }
    end
  end
end
