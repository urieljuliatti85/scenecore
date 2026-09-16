require "rails_helper"

RSpec.describe Subscription, type: :model do
  it "is valid with valid attributes" do
    expect(build(:subscription)).to be_valid
  end

  it "requires a user" do
    subscription = build(:subscription, user: nil)

    expect(subscription).not_to be_valid
  end

  it "requires a band" do
    subscription = build(:subscription, band: nil)

    expect(subscription).not_to be_valid
  end

  it "requires a stripe_customer_id" do
    subscription = build(:subscription, stripe_customer_id: nil)

    expect(subscription).not_to be_valid
  end

  it "defaults status to pending" do
    expect(create(:subscription).status).to eq("pending")
  end

  it "restricts level to fan, supporter, or core_member" do
    subscription = build(:subscription)
    subscription.level = "vip"

    expect(subscription).not_to be_valid
  end

  it "restricts status to pending, active, past_due, cancelled, or expired" do
    subscription = build(:subscription)
    subscription.status = "unknown"

    expect(subscription).not_to be_valid
  end

  it "only allows one subscription per user per band" do
    band = create(:band)
    user = create(:user)
    create(:subscription, user: user, band: band)

    duplicate = build(:subscription, user: user, band: band)

    expect(duplicate).not_to be_valid
  end

  it "allows the same user to have subscriptions with different bands" do
    user = create(:user)
    create(:subscription, user: user, band: create(:band))

    other_band_subscription = build(:subscription, user: user, band: create(:band))

    expect(other_band_subscription).to be_valid
  end
end
