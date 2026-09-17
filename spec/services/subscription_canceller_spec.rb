require "rails_helper"

RSpec.describe SubscriptionCanceller do
  let(:stripe_subscriptions) { instance_double(Stripe::SubscriptionService) }

  before do
    allow(StripeClient).to receive(:instance)
      .and_return(instance_double(Stripe::StripeClient, v1: instance_double(Stripe::V1Services, subscriptions: stripe_subscriptions)))
  end

  describe ".call" do
    it "stops Stripe billing and cancels both records" do
      membership = create(:membership, status: :active)
      subscription = create(:subscription, :active, band: membership.band, user: membership.user,
                                                    stripe_subscription_id: "sub_1")
      allow(stripe_subscriptions).to receive(:cancel)

      described_class.call(band: membership.band, user: membership.user)

      expect(stripe_subscriptions).to have_received(:cancel).with("sub_1")
      expect(subscription.reload).to be_cancelled
      expect(membership.reload).to be_cancelled
    end

    it "cancels a membership granted with no subscription behind it" do
      membership = create(:membership, status: :active)
      allow(stripe_subscriptions).to receive(:cancel)

      described_class.call(band: membership.band, user: membership.user)

      expect(stripe_subscriptions).not_to have_received(:cancel)
      expect(membership.reload).to be_cancelled
    end

    it "skips Stripe for a subscription that never completed checkout" do
      membership = create(:membership, status: :active)
      create(:subscription, band: membership.band, user: membership.user, stripe_subscription_id: nil)
      allow(stripe_subscriptions).to receive(:cancel)

      described_class.call(band: membership.band, user: membership.user)

      expect(stripe_subscriptions).not_to have_received(:cancel)
      expect(membership.reload).to be_cancelled
    end

    # Already cancelled on Stripe's side: the local records are still the
    # ones out of step, so they should be brought in line rather than left
    # granting access nobody is paying for.
    it "still cancels locally when Stripe no longer has the subscription" do
      membership = create(:membership, status: :active)
      subscription = create(:subscription, :active, band: membership.band, user: membership.user,
                                                    stripe_subscription_id: "sub_gone")
      allow(stripe_subscriptions).to receive(:cancel)
        .and_raise(Stripe::InvalidRequestError.new("No such subscription: sub_gone", "id"))

      described_class.call(band: membership.band, user: membership.user)

      expect(subscription.reload).to be_cancelled
      expect(membership.reload).to be_cancelled
    end

    it "raises without cancelling locally when Stripe cannot be reached" do
      membership = create(:membership, status: :active)
      create(:subscription, :active, band: membership.band, user: membership.user, stripe_subscription_id: "sub_1")
      allow(stripe_subscriptions).to receive(:cancel).and_raise(Stripe::APIConnectionError.new("network down"))

      expect {
        described_class.call(band: membership.band, user: membership.user)
      }.to raise_error(described_class::Error)

      expect(membership.reload).to be_active
    end
  end
end
