require "rails_helper"

RSpec.describe CommentPolicy do
  let(:band) { create(:band, :approved) }

  describe "#create?" do
    subject { described_class.new(user, comment) }

    let(:comment) { build(:comment, post: post) }

    context "when the post is public" do
      let(:post) { create(:post, :published, band: band, visibility: :public) }

      context "and the user is signed in" do
        let(:user) { create(:user) }

        it { expect(subject.create?).to be true }
      end

      context "and the user is anonymous" do
        let(:user) { nil }

        it { expect(subject.create?).to be false }
      end
    end

    context "when the post is followers-only" do
      let(:post) { create(:post, :published, band: band, visibility: :followers) }

      context "and the user follows the band" do
        let(:user) { create(:user) }
        before { create(:follow, band: band, user: user) }

        it { expect(subject.create?).to be true }
      end

      context "and the user does not follow the band" do
        let(:user) { create(:user) }

        it { expect(subject.create?).to be false }
      end
    end

    context "when the post requires a paid membership level the user does not have" do
      let(:post) { create(:post, :published, band: band, visibility: :supporter) }
      let(:user) { create(:user) }
      before { create(:membership, band: band, user: user, level: :fan) }

      it { expect(subject.create?).to be false }
    end
  end

  describe "#destroy?" do
    subject { described_class.new(user, comment) }

    let(:post) { create(:post, :published, band: band) }
    let(:author) { create(:user) }
    let(:comment) { create(:comment, post: post, user: author) }

    context "when the user is the comment's author" do
      let(:user) { author }

      it { expect(subject.destroy?).to be true }
    end

    context "when the user is a member of the band that owns the post" do
      let(:user) { create(:user) }
      before { create(:band_membership, band: band, user: user) }

      it { expect(subject.destroy?).to be true }
    end

    context "when the user is a platform administrator" do
      let(:user) { create(:user, :platform_admin) }

      it { expect(subject.destroy?).to be true }
    end

    context "when the user is an unrelated fan" do
      let(:user) { create(:user) }

      it { expect(subject.destroy?).to be false }
    end

    context "when the user is anonymous" do
      let(:user) { nil }

      it { expect(subject.destroy?).to be false }
    end
  end
end
