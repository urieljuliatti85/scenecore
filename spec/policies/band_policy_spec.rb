require "rails_helper"

RSpec.describe BandPolicy do
  subject { described_class.new(user, band) }

  let(:band) { create(:band) }

  describe "#show?" do
    context "when user is a member of the band" do
      let(:user) { create(:user) }
      before { create(:band_membership, band: band, user: user) }

      it { is_expected.to be_show }
    end

    context "when user is an administrator of the band" do
      let(:user) { create(:user) }
      before { create(:band_membership, :administrator, band: band, user: user) }

      it { is_expected.to be_show }
    end

    context "when user is a platform admin but not a member" do
      let(:user) { create(:user, :platform_admin) }

      it { is_expected.to be_show }
    end

    context "when user is not a member and not a platform admin" do
      let(:user) { create(:user) }

      it { is_expected.not_to be_show }
    end

    context "when user is a member of a different band" do
      let(:user) { create(:user) }
      before { create(:band_membership, band: create(:band), user: user) }

      it { is_expected.not_to be_show }
    end
  end

  describe "#create?" do
    context "when authenticated" do
      let(:user) { create(:user) }

      it { is_expected.to be_create }
    end

    context "when anonymous" do
      let(:user) { nil }

      it { is_expected.not_to be_create }
    end
  end

  describe "#update?" do
    context "when user is an administrator of the band" do
      let(:user) { create(:user) }
      before { create(:band_membership, :administrator, band: band, user: user) }

      it { is_expected.to be_update }
    end

    context "when user is a plain member of the band" do
      let(:user) { create(:user) }
      before { create(:band_membership, band: band, user: user) }

      it { is_expected.not_to be_update }
    end

    context "when user is a platform admin but not a member" do
      let(:user) { create(:user, :platform_admin) }

      it { is_expected.to be_update }
    end

    context "when user is an administrator of a different band" do
      let(:user) { create(:user) }
      before { create(:band_membership, :administrator, band: create(:band), user: user) }

      it { is_expected.not_to be_update }
    end
  end

  describe "#approve? and #reject?" do
    context "when user is a platform admin" do
      let(:user) { create(:user, :platform_admin) }

      it { is_expected.to be_approve }
      it { is_expected.to be_reject }
    end

    context "when user is the band's own administrator" do
      let(:user) { create(:user) }
      before { create(:band_membership, :administrator, band: band, user: user) }

      it { is_expected.not_to be_approve }
      it { is_expected.not_to be_reject }
    end

    context "when user is a regular user" do
      let(:user) { create(:user) }

      it { is_expected.not_to be_approve }
      it { is_expected.not_to be_reject }
    end
  end

  describe "#suspend? and #reactivate?" do
    context "when user is a platform admin" do
      let(:user) { create(:user, :platform_admin) }

      it { is_expected.to be_suspend }
      it { is_expected.to be_reactivate }
    end

    context "when user is the band's own administrator" do
      let(:user) { create(:user) }
      before { create(:band_membership, :administrator, band: band, user: user) }

      it { is_expected.not_to be_suspend }
      it { is_expected.not_to be_reactivate }
    end

    context "when user is a regular user" do
      let(:user) { create(:user) }

      it { is_expected.not_to be_suspend }
      it { is_expected.not_to be_reactivate }
    end
  end

  describe "Scope" do
    subject { BandPolicy::Scope.new(user, Band).resolve }

    let!(:member_band) { create(:band) }
    let!(:other_band) { create(:band) }

    context "when user is a member of one band" do
      let(:user) { create(:user) }
      before { create(:band_membership, band: member_band, user: user) }

      it { is_expected.to contain_exactly(member_band) }
    end

    context "when user is a platform admin" do
      let(:user) { create(:user, :platform_admin) }

      it { is_expected.to contain_exactly(member_band, other_band) }
    end

    context "when user is anonymous" do
      let(:user) { nil }

      it { is_expected.to be_empty }
    end
  end
end
