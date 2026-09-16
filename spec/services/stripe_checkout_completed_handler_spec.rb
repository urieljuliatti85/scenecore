require "rails_helper"

RSpec.describe StripeCheckoutCompletedHandler do
  describe ".call" do
    it "activates the subscription and grants the membership when payment succeeded" do
      subscription = create(:subscription, level: :supporter, stripe_checkout_session_id: "cs_123")
      session = instance_double(Stripe::Checkout::Session,
        id: "cs_123", payment_status: "paid", subscription: "sub_456")

      described_class.call(session)

      subscription.reload
      expect(subscription.status).to eq("active")
      expect(subscription.stripe_subscription_id).to eq("sub_456")

      membership = Membership.find_by(user: subscription.user, band: subscription.band)
      expect(membership.level).to eq("supporter")
      expect(membership.status).to eq("active")
    end

    it "upgrades an existing membership's level instead of creating a duplicate" do
      subscription = create(:subscription, level: :core_member, stripe_checkout_session_id: "cs_123")
      create(:membership, user: subscription.user, band: subscription.band, level: :fan, status: :active)
      session = instance_double(Stripe::Checkout::Session,
        id: "cs_123", payment_status: "paid", subscription: "sub_456")

      described_class.call(session)

      expect(Membership.where(user: subscription.user, band: subscription.band).count).to eq(1)
      expect(Membership.find_by(user: subscription.user, band: subscription.band).level).to eq("core_member")
    end

    it "does nothing when payment has not actually succeeded" do
      subscription = create(:subscription, stripe_checkout_session_id: "cs_123")
      session = instance_double(Stripe::Checkout::Session,
        id: "cs_123", payment_status: "unpaid", subscription: "sub_456")

      described_class.call(session)

      expect(subscription.reload.status).to eq("pending")
      expect(Membership.find_by(user: subscription.user, band: subscription.band)).to be_nil
    end

    it "does nothing when no local subscription matches the session id" do
      session = instance_double(Stripe::Checkout::Session,
        id: "cs_unknown", payment_status: "paid", subscription: "sub_456")

      expect { described_class.call(session) }.not_to raise_error
    end
  end
end
