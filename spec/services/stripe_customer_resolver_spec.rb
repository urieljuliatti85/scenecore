require "rails_helper"

RSpec.describe StripeCustomerResolver do
  let(:customers_service) { instance_double(Stripe::CustomerService) }
  let(:v1) { instance_double(Stripe::V1Services, customers: customers_service) }
  let(:stripe_client) { instance_double(Stripe::StripeClient, v1: v1) }

  before do
    allow(StripeClient).to receive(:instance).and_return(stripe_client)
  end

  describe ".resolve" do
    it "returns the existing stripe_customer_id without calling Stripe" do
      user = create(:user, stripe_customer_id: "cus_existing")
      allow(customers_service).to receive(:create)

      customer_id = described_class.resolve(user)

      expect(customer_id).to eq("cus_existing")
      expect(customers_service).not_to have_received(:create)
    end

    it "creates a Stripe customer and persists it when the user has none yet" do
      user = create(:user, stripe_customer_id: nil)
      customer = instance_double(Stripe::Customer, id: "cus_new")
      allow(customers_service).to receive(:create).and_return(customer)

      customer_id = described_class.resolve(user)

      expect(customer_id).to eq("cus_new")
      expect(user.reload.stripe_customer_id).to eq("cus_new")
      expect(customers_service).to have_received(:create).with(
        hash_including(email: user.email, metadata: { user_id: user.id })
      )
    end

    it "wraps a Stripe error" do
      user = create(:user, stripe_customer_id: nil)
      allow(customers_service).to receive(:create).and_raise(Stripe::APIConnectionError.new("network down"))

      expect { described_class.resolve(user) }.to raise_error(StripeCustomerResolver::Error)
    end
  end
end
