require "rails_helper"

RSpec.describe StripeClient do
  before do
    described_class.instance_variable_set(:@instance, nil)
    allow(Rails.application.credentials).to receive(:dig).with(:stripe, :secret_key).and_return("sk_test_dummy")
  end

  after do
    described_class.instance_variable_set(:@instance, nil)
  end

  describe ".instance" do
    it "returns a Stripe::StripeClient instance" do
      expect(described_class.instance).to be_a(Stripe::StripeClient)
    end

    it "memoizes the client instead of rebuilding it on every call" do
      expect(described_class.instance).to equal(described_class.instance)
    end
  end
end
