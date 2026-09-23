require "rails_helper"

RSpec.describe BandMembershipPolicy do
  subject { described_class.new(user, membership) }

  let(:band) { create(:band) }
  let(:membership) { build(:band_membership, band: band) }

  describe "#create?, #update?, #destroy?" do
    context "when user is an administrator of the band" do
      let(:user) { create(:user) }
      before { create(:band_membership, :administrator, band: band, user: user) }

      it { is_expected.to be_create }
      it { is_expected.to be_update }
      it { is_expected.to be_destroy }
    end

    context "when user is a plain member of the band" do
      let(:user) { create(:user) }
      before { create(:band_membership, band: band, user: user) }

      it { is_expected.not_to be_create }
      it { is_expected.not_to be_update }
      it { is_expected.not_to be_destroy }
    end

    context "when user is not in the band at all" do
      let(:user) { create(:user) }

      it { is_expected.not_to be_create }
      it { is_expected.not_to be_update }
      it { is_expected.not_to be_destroy }
    end

    context "when user is an administrator of a different band" do
      let(:user) { create(:user) }
      before { create(:band_membership, :administrator, band: create(:band), user: user) }

      it { is_expected.not_to be_create }
      it { is_expected.not_to be_update }
      it { is_expected.not_to be_destroy }
    end

    context "when user is a platform administrator not in the band" do
      let(:user) { create(:user, :platform_admin) }

      it { is_expected.not_to be_create }
      it { is_expected.not_to be_update }
      it { is_expected.not_to be_destroy }
    end

    context "when user is anonymous" do
      let(:user) { nil }

      it { is_expected.not_to be_create }
      it { is_expected.not_to be_update }
      it { is_expected.not_to be_destroy }
    end
  end

  describe "#index?" do
    subject { described_class.new(user, BandMembership.new(band: band)) }

    context "when user is an administrator of the band" do
      let(:user) { create(:user) }
      before { create(:band_membership, :administrator, band: band, user: user) }

      it { is_expected.to be_index }
    end

    context "when user is a platform administrator not in the band" do
      let(:user) { create(:user, :platform_admin) }

      it { is_expected.not_to be_index }
    end

    context "when user is not in the band at all" do
      let(:user) { create(:user) }

      it { is_expected.not_to be_index }
    end
  end
end
