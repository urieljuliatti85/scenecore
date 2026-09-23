require "rails_helper"

RSpec.describe BandSubscriptionsCanceller do
  let(:band) { create(:band) }
  let(:stripe_subscriptions) { instance_double(Stripe::SubscriptionService) }

  before do
    allow(StripeClient).to receive(:instance)
      .and_return(instance_double(Stripe::StripeClient, v1: instance_double(Stripe::V1Services, subscriptions: stripe_subscriptions)))
    allow(stripe_subscriptions).to receive(:cancel)
  end

  describe ".call" do
    it "cancels every active subscription and the membership it granted" do
      membership = create(:membership, status: :active, band: band)
      subscription = create(:subscription, :active, band: band, user: membership.user,
                                                    stripe_subscription_id: "sub_1")

      described_class.call(band)

      expect(stripe_subscriptions).to have_received(:cancel).with("sub_1")
      expect(subscription.reload).to be_cancelled
      expect(membership.reload).to be_cancelled
    end

    it "also cancels a subscription that is past_due" do
      membership = create(:membership, status: :active, band: band)
      subscription = create(:subscription, :past_due, band: band, user: membership.user,
                                                      stripe_subscription_id: "sub_2")

      described_class.call(band)

      expect(subscription.reload).to be_cancelled
    end

    it "leaves an already-cancelled subscription alone" do
      subscription = create(:subscription, :cancelled, band: band)

      described_class.call(band)

      expect(stripe_subscriptions).not_to have_received(:cancel)
      expect(subscription.reload).to be_cancelled
    end

    it "does not touch another band's subscriptions" do
      other_band = create(:band)
      other_membership = create(:membership, status: :active, band: other_band)
      other_subscription = create(:subscription, :active, band: other_band, user: other_membership.user)

      described_class.call(band)

      expect(other_subscription.reload).to be_active
      expect(other_membership.reload).to be_active
    end

    it "reports how many were cancelled" do
      membership_a = create(:membership, status: :active, band: band)
      create(:subscription, :active, band: band, user: membership_a.user, stripe_subscription_id: "sub_a")
      membership_b = create(:membership, status: :active, band: band)
      create(:subscription, :active, band: band, user: membership_b.user, stripe_subscription_id: "sub_b")

      result = described_class.call(band)

      expect(result.cancelled_count).to eq(2)
      expect(result.failed_count).to eq(0)
    end

    it "does nothing, and reports nothing, when the band has no billing subscriptions" do
      result = described_class.call(band)

      expect(result.cancelled_count).to eq(0)
      expect(result.failed_count).to eq(0)
    end

    # One unreachable Stripe subscription must not stop the rest — every
    # fan left billing is money still being taken.
    it "keeps cancelling the rest when one subscription's Stripe call fails, and reports the failure" do
      failing_membership = create(:membership, status: :active, band: band)
      create(:subscription, :active, band: band, user: failing_membership.user, stripe_subscription_id: "sub_fail")
      ok_membership = create(:membership, status: :active, band: band)
      create(:subscription, :active, band: band, user: ok_membership.user, stripe_subscription_id: "sub_ok")

      allow(stripe_subscriptions).to receive(:cancel).with("sub_fail")
        .and_raise(Stripe::APIConnectionError.new("network down"))

      result = described_class.call(band)

      expect(failing_membership.reload).to be_active
      expect(ok_membership.reload).to be_cancelled
      expect(result.cancelled_count).to eq(1)
      expect(result.failed_count).to eq(1)
    end
  end
end
