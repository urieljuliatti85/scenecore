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

  describe ".orphaned" do
    def subscription_for(membership_status, subscription_status: :active)
      band = create(:band)
      user = create(:user)
      create(:membership, band: band, user: user, status: membership_status) if membership_status
      create(:subscription, band: band, user: user, status: subscription_status)
    end

    it "finds a subscription still billing for a cancelled membership" do
      subscription = subscription_for(:cancelled)

      expect(described_class.orphaned).to contain_exactly(subscription)
    end

    it "finds one billing for a paused membership" do
      subscription = subscription_for(:paused)

      expect(described_class.orphaned).to contain_exactly(subscription)
    end

    it "finds one whose membership was deleted outright" do
      subscription = subscription_for(nil)

      expect(described_class.orphaned).to contain_exactly(subscription)
    end

    # Stripe is still retrying the charge, so the fan is still being billed.
    it "finds a past_due subscription without an active membership" do
      subscription = subscription_for(:cancelled, subscription_status: :past_due)

      expect(described_class.orphaned).to contain_exactly(subscription)
    end

    it "ignores a subscription whose membership is active" do
      subscription_for(:active)

      expect(described_class.orphaned).to be_empty
    end

    it "ignores a subscription that is no longer billing" do
      subscription_for(:cancelled, subscription_status: :cancelled)
      subscription_for(:cancelled, subscription_status: :expired)
      subscription_for(:cancelled, subscription_status: :pending)

      expect(described_class.orphaned).to be_empty
    end

    # The memberships are matched per band, so another band's active
    # membership must not make a subscription look healthy.
    it "does not treat an active membership with a different band as cover" do
      user = create(:user)
      band = create(:band)
      create(:membership, band: band, user: user, status: :cancelled)
      create(:membership, band: create(:band), user: user, status: :active)
      subscription = create(:subscription, band: band, user: user, status: :active)

      expect(described_class.orphaned).to contain_exactly(subscription)
    end
  end
end
