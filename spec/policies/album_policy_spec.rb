require "rails_helper"

RSpec.describe AlbumPolicy do
  subject { described_class.new(user, album) }

  let(:band) { create(:band) }
  let(:album) { build(:album, band: band) }

  describe "#create?" do
    context "when user is an administrator of the band" do
      let(:user) { create(:user) }
      before { create(:band_membership, :administrator, band: band, user: user) }

      it { is_expected.to be_create }
    end

    context "when user is a plain member of the band" do
      let(:user) { create(:user) }
      before { create(:band_membership, band: band, user: user) }

      it { is_expected.to be_create }
    end

    context "when user is not in the band at all" do
      let(:user) { create(:user) }

      it { is_expected.not_to be_create }
    end

    context "when user is a member of a different band" do
      let(:user) { create(:user) }
      before { create(:band_membership, band: create(:band), user: user) }

      it { is_expected.not_to be_create }
    end

    context "when user is anonymous" do
      let(:user) { nil }

      it { is_expected.not_to be_create }
    end
  end

  describe "#search?" do
    context "when user is a member of the band" do
      let(:user) { create(:user) }
      before { create(:band_membership, band: band, user: user) }

      it { is_expected.to be_search }
    end

    context "when user is not in the band at all" do
      let(:user) { create(:user) }

      it { is_expected.not_to be_search }
    end
  end
end
