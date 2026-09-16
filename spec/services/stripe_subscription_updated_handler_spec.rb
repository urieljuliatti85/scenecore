require "rails_helper"

RSpec.describe StripeSubscriptionUpdatedHandler do
  describe ".call" do
    it "marks the subscription and membership past_due/paused when Stripe reports past_due" do
      subscription = create(:subscription, :active, stripe_subscription_id: "sub_1")
      create(:membership, user: subscription.user, band: subscription.band, level: subscription.level, status: :active)
      stripe_subscription = instance_double(Stripe::Subscription, id: "sub_1", status: "past_due")

      described_class.call(stripe_subscription)

      expect(subscription.reload.status).to eq("past_due")
      membership = Membership.find_by(user: subscription.user, band: subscription.band)
      expect(membership.status).to eq("paused")
    end

    it "reactivates the subscription and membership when Stripe reports active again" do
      subscription = create(:subscription, :past_due, stripe_subscription_id: "sub_1")
      create(:membership, user: subscription.user, band: subscription.band, level: subscription.level, status: :paused)
      stripe_subscription = instance_double(Stripe::Subscription, id: "sub_1", status: "active")

      described_class.call(stripe_subscription)

      expect(subscription.reload.status).to eq("active")
      membership = Membership.find_by(user: subscription.user, band: subscription.band)
      expect(membership.status).to eq("active")
    end

    it "does nothing when no local subscription matches the stripe subscription id" do
      stripe_subscription = instance_double(Stripe::Subscription, id: "sub_unknown", status: "active")

      expect { described_class.call(stripe_subscription) }.not_to raise_error
    end

    it "does nothing for a status it does not map" do
      subscription = create(:subscription, :active, stripe_subscription_id: "sub_1")
      stripe_subscription = instance_double(Stripe::Subscription, id: "sub_1", status: "incomplete")

      described_class.call(stripe_subscription)

      expect(subscription.reload.status).to eq("active")
    end
  end
end
