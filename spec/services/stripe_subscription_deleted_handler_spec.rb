require "rails_helper"

RSpec.describe StripeSubscriptionDeletedHandler do
  describe ".call" do
    it "cancels the subscription and membership" do
      subscription = create(:subscription, :active, stripe_subscription_id: "sub_1")
      create(:membership, user: subscription.user, band: subscription.band, level: subscription.level, status: :active)
      stripe_subscription = instance_double(Stripe::Subscription, id: "sub_1")

      described_class.call(stripe_subscription)

      expect(subscription.reload.status).to eq("cancelled")
      membership = Membership.find_by(user: subscription.user, band: subscription.band)
      expect(membership.status).to eq("cancelled")
    end

    it "does nothing when no local subscription matches the stripe subscription id" do
      stripe_subscription = instance_double(Stripe::Subscription, id: "sub_unknown")

      expect { described_class.call(stripe_subscription) }.not_to raise_error
    end

    it "does nothing to the membership when none exists" do
      subscription = create(:subscription, :active, stripe_subscription_id: "sub_1")
      stripe_subscription = instance_double(Stripe::Subscription, id: "sub_1")

      expect { described_class.call(stripe_subscription) }.not_to raise_error
      expect(subscription.reload.status).to eq("cancelled")
    end
  end
end
