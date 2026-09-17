require "rails_helper"

RSpec.describe AlbumCreditPolicy do
  subject { described_class.new(user, credit) }

  let(:band) { create(:band) }
  let(:album) { create(:album, band: band) }
  let(:credit) { build(:album_credit, album: album) }

  %i[create? destroy?].each do |action|
    describe "##{action}" do
      context "when user is a member of the band" do
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

      context "when user is a platform administrator not in the band" do
        let(:user) { create(:user, :platform_admin) }

        it { expect(subject.public_send(action)).to be true }
      end

      context "when user is anonymous" do
        let(:user) { nil }

        it { expect(subject.public_send(action)).to be false }
      end
    end
  end
end
