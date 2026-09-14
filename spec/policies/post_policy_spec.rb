require "rails_helper"

RSpec.describe PostPolicy do
  subject { described_class.new(user, post) }

  let(:band) { create(:band) }
  let(:post) { build(:post, band: band) }

  %i[create? update? destroy? publish? unpublish?].each do |action|
    describe "##{action}" do
      context "when user is an administrator of the band" do
        let(:user) { create(:user) }
        before { create(:band_membership, :administrator, band: band, user: user) }

        it { expect(subject.public_send(action)).to be true }
      end

      context "when user is a plain member of the band" do
        let(:user) { create(:user) }
        before { create(:band_membership, band: band, user: user) }

        it { expect(subject.public_send(action)).to be true }
      end

      context "when user is not in the band at all" do
        let(:user) { create(:user) }

        it { expect(subject.public_send(action)).to be false }
      end

      context "when user is a member of a different band" do
        let(:user) { create(:user) }
        before { create(:band_membership, band: create(:band), user: user) }

        it { expect(subject.public_send(action)).to be false }
      end

      context "when user is anonymous" do
        let(:user) { nil }

        it { expect(subject.public_send(action)).to be false }
      end
    end
  end
end
