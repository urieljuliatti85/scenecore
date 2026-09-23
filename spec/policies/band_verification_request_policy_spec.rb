require "rails_helper"

RSpec.describe BandVerificationRequestPolicy do
  let(:band) { create(:band) }

  describe "#create?" do
    subject { described_class.new(user, BandVerificationRequest.new(band: band)) }

    context "when user is an administrator of the band" do
      let(:user) { create(:user) }
      before { create(:band_membership, :administrator, band: band, user: user) }

      it { is_expected.to be_create }
    end

    context "when user is a plain member of the band" do
      let(:user) { create(:user) }
      before { create(:band_membership, band: band, user: user) }

      it { is_expected.not_to be_create }
    end

    context "when user is not in the band at all" do
      let(:user) { create(:user) }

      it { is_expected.not_to be_create }
    end

    context "when user is an administrator of a different band" do
      let(:user) { create(:user) }
      before { create(:band_membership, :administrator, band: create(:band), user: user) }

      it { is_expected.not_to be_create }
    end

    # Submitting a band's own email for verification is day-to-day band
    # work, same bar as manage_payments? — no platform-admin bypass.
    context "when user is a platform administrator without a membership" do
      let(:user) { create(:user, :platform_admin) }

      it { is_expected.not_to be_create }
    end

    context "when user is anonymous" do
      let(:user) { nil }

      it { is_expected.not_to be_create }
    end
  end

  describe "#approve?, #reject?, #resend?" do
    subject { described_class.new(user, create(:band_verification_request, band: band)) }

    context "when user is a platform administrator" do
      let(:user) { create(:user, :platform_admin) }

      it { is_expected.to be_approve }
      it { is_expected.to be_reject }
      it { is_expected.to be_resend }
    end

    context "when user is the band's own administrator" do
      let(:user) { create(:user) }
      before { create(:band_membership, :administrator, band: band, user: user) }

      it { is_expected.not_to be_approve }
      it { is_expected.not_to be_reject }
      it { is_expected.not_to be_resend }
    end

    context "when user is a regular user" do
      let(:user) { create(:user) }

      it { is_expected.not_to be_approve }
      it { is_expected.not_to be_reject }
      it { is_expected.not_to be_resend }
    end

    context "when there is no user" do
      let(:user) { nil }

      it { is_expected.not_to be_approve }
      it { is_expected.not_to be_reject }
      it { is_expected.not_to be_resend }
    end
  end
end
