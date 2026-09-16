require "rails_helper"

RSpec.describe MembershipPolicy do
  subject { described_class.new(user, membership) }

  let(:band) { create(:band) }
  let(:owner) { create(:user) }
  let(:membership) { create(:membership, band: band, user: owner) }

  describe "#show?" do
    context "when user is the membership owner" do
      let(:user) { owner }

      it { is_expected.to be_show }
    end

    context "when user is an administrator of the band" do
      let(:user) { create(:user) }
      before { create(:band_membership, :administrator, band: band, user: user) }

      it { is_expected.to be_show }
    end

    context "when user is a platform administrator" do
      let(:user) { create(:user, :platform_admin) }

      it { is_expected.to be_show }
    end

    context "when user is an unrelated user" do
      let(:user) { create(:user) }

      it { is_expected.not_to be_show }
    end

    context "when user is an administrator of a different band" do
      let(:user) { create(:user) }
      before { create(:band_membership, :administrator, band: create(:band), user: user) }

      it { is_expected.not_to be_show }
    end

    context "when user is anonymous" do
      let(:user) { nil }

      it { is_expected.not_to be_show }
    end
  end

  describe "#index?" do
    context "when user is an administrator of the band" do
      let(:user) { create(:user) }
      before { create(:band_membership, :administrator, band: band, user: user) }

      it { is_expected.to be_index }
    end

    context "when user is a platform administrator" do
      let(:user) { create(:user, :platform_admin) }

      it { is_expected.to be_index }
    end

    context "when user only owns a membership but does not administer the band" do
      let(:user) { owner }

      it { is_expected.not_to be_index }
    end

    context "when user is anonymous" do
      let(:user) { nil }

      it { is_expected.not_to be_index }
    end
  end

  describe "#create?, #update?, #destroy?" do
    context "when user is an administrator of the band" do
      let(:user) { create(:user) }
      before { create(:band_membership, :administrator, band: band, user: user) }

      it { is_expected.to be_create }
      it { is_expected.to be_update }
      it { is_expected.to be_destroy }
    end

    context "when user is a platform administrator" do
      let(:user) { create(:user, :platform_admin) }

      it { is_expected.not_to be_create }
      it { is_expected.not_to be_update }
      it { is_expected.not_to be_destroy }
    end

    context "when user only owns the membership" do
      let(:user) { owner }

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

    context "when user is anonymous" do
      let(:user) { nil }

      it { is_expected.not_to be_create }
      it { is_expected.not_to be_update }
      it { is_expected.not_to be_destroy }
    end
  end

  describe "#join?" do
    let(:approved_band) { create(:band, :approved) }

    context "when the membership is a new record for an approved band" do
      subject { described_class.new(user, Membership.new(band: approved_band)) }
      let(:user) { create(:user) }

      it { is_expected.to be_join }
    end

    context "when the band is not approved" do
      subject { described_class.new(user, Membership.new(band: band)) }
      let(:user) { create(:user) }

      it { is_expected.not_to be_join }
    end

    context "when the user is anonymous" do
      subject { described_class.new(user, Membership.new(band: approved_band)) }
      let(:user) { nil }

      it { is_expected.not_to be_join }
    end

    context "when updating their own existing membership" do
      let(:membership) { create(:membership, band: approved_band, user: owner) }
      let(:user) { owner }

      it { is_expected.to be_join }
    end

    context "when the record belongs to a different user" do
      let(:membership) { create(:membership, band: approved_band, user: owner) }
      let(:user) { create(:user) }

      it { is_expected.not_to be_join }
    end
  end

  describe "#pause?, #cancel?, #reactivate?" do
    context "when user is an administrator of the band" do
      let(:user) { create(:user) }
      before { create(:band_membership, :administrator, band: band, user: user) }

      it { is_expected.to be_pause }
      it { is_expected.to be_cancel }
      it { is_expected.to be_reactivate }
    end

    context "when user is a platform administrator" do
      let(:user) { create(:user, :platform_admin) }

      it { is_expected.to be_pause }
      it { is_expected.to be_cancel }
      it { is_expected.to be_reactivate }
    end

    context "when user only owns the membership" do
      let(:user) { owner }

      it { is_expected.not_to be_pause }
      it { is_expected.not_to be_cancel }
      it { is_expected.not_to be_reactivate }
    end

    context "when user is an administrator of a different band" do
      let(:user) { create(:user) }
      before { create(:band_membership, :administrator, band: create(:band), user: user) }

      it { is_expected.not_to be_pause }
      it { is_expected.not_to be_cancel }
      it { is_expected.not_to be_reactivate }
    end

    context "when user is anonymous" do
      let(:user) { nil }

      it { is_expected.not_to be_pause }
      it { is_expected.not_to be_cancel }
      it { is_expected.not_to be_reactivate }
    end
  end

  describe "Scope" do
    subject { MembershipPolicy::Scope.new(user, Membership).resolve }

    let(:other_band) { create(:band) }
    let!(:own_membership) { create(:membership, band: band, user: owner) }
    let!(:other_users_membership) { create(:membership, band: other_band, user: create(:user)) }

    context "when user is a platform administrator" do
      let(:user) { create(:user, :platform_admin) }

      it "returns every membership" do
        expect(subject).to contain_exactly(own_membership, other_users_membership)
      end
    end

    context "when user administers a band" do
      let(:user) { create(:user) }
      before { create(:band_membership, :administrator, band: band, user: user) }

      it "returns memberships for that band" do
        expect(subject).to contain_exactly(own_membership)
      end
    end

    context "when user only owns a membership" do
      let(:user) { owner }

      it "returns their own membership" do
        expect(subject).to contain_exactly(own_membership)
      end
    end

    context "when user is anonymous" do
      let(:user) { nil }

      it "returns none" do
        expect(subject).to be_empty
      end
    end
  end
end
