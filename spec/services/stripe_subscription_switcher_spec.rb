require "rails_helper"

RSpec.describe StripeSubscriptionSwitcher do
  let(:subscriptions_service) { instance_double(Stripe::SubscriptionService) }
  let(:v1) { instance_double(Stripe::V1Services, subscriptions: subscriptions_service) }
  let(:stripe_client) { instance_double(Stripe::StripeClient, v1: v1) }

  before do
    allow(StripeClient).to receive(:instance).and_return(stripe_client)
  end

  describe ".call" do
    it "replaces the existing subscription item's price rather than adding a second item" do
      item = instance_double(Stripe::SubscriptionItem, id: "si_1", price: instance_double(Stripe::Price, id: "price_fan"))
      items = double(data: [ item ])
      subscription = instance_double(Stripe::Subscription, items: items)
      allow(subscriptions_service).to receive(:retrieve).with("sub_1").and_return(subscription)
      allow(subscriptions_service).to receive(:update)

      described_class.call("sub_1", "price_supporter")

      expect(subscriptions_service).to have_received(:update).with(
        "sub_1", items: [ { id: "si_1", price: "price_supporter" } ]
      )
    end

    it "does nothing when the subscription is already on the requested price" do
      item = instance_double(Stripe::SubscriptionItem, id: "si_1", price: instance_double(Stripe::Price, id: "price_fan"))
      items = double(data: [ item ])
      subscription = instance_double(Stripe::Subscription, items: items)
      allow(subscriptions_service).to receive(:retrieve).with("sub_1").and_return(subscription)
      allow(subscriptions_service).to receive(:update)

      described_class.call("sub_1", "price_fan")

      expect(subscriptions_service).not_to have_received(:update)
    end

    it "raises a wrapped error when Stripe rejects the update" do
      item = instance_double(Stripe::SubscriptionItem, id: "si_1", price: instance_double(Stripe::Price, id: "price_fan"))
      items = double(data: [ item ])
      subscription = instance_double(Stripe::Subscription, items: items)
      allow(subscriptions_service).to receive(:retrieve).with("sub_1").and_return(subscription)
      allow(subscriptions_service).to receive(:update).and_raise(Stripe::InvalidRequestError.new("no such subscription", "id"))

      expect { described_class.call("sub_1", "price_supporter") }.to raise_error(StripeSubscriptionSwitcher::Error, /Could not change your subscription level/)
    end

    it "raises when the subscription has no items" do
      items = double(data: [])
      subscription = instance_double(Stripe::Subscription, items: items)
      allow(subscriptions_service).to receive(:retrieve).with("sub_1").and_return(subscription)

      expect { described_class.call("sub_1", "price_supporter") }.to raise_error(StripeSubscriptionSwitcher::Error, /has no items to switch/)
    end
  end
end
