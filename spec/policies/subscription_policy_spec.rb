require "rails_helper"

RSpec.describe SubscriptionPolicy do
  describe "#join?" do
    let(:approved_band) { create(:band, :approved) }
    let(:owner) { create(:user) }

    context "when the subscription is a new record for an approved band" do
      subject { described_class.new(user, Subscription.new(band: approved_band)) }
      let(:user) { create(:user) }

      it { is_expected.to be_join }
    end

    context "when the band is not approved" do
      subject { described_class.new(user, Subscription.new(band: create(:band))) }
      let(:user) { create(:user) }

      it { is_expected.not_to be_join }
    end

    context "when the user is anonymous" do
      subject { described_class.new(user, Subscription.new(band: approved_band)) }
      let(:user) { nil }

      it { is_expected.not_to be_join }
    end

    context "when updating their own existing subscription" do
      subject { described_class.new(user, subscription) }
      let(:subscription) { create(:subscription, band: approved_band, user: owner) }
      let(:user) { owner }

      it { is_expected.to be_join }
    end

    context "when the record belongs to a different user" do
      subject { described_class.new(user, subscription) }
      let(:subscription) { create(:subscription, band: approved_band, user: owner) }
      let(:user) { create(:user) }

      it { is_expected.not_to be_join }
    end
  end
end
