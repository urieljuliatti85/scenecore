require "rails_helper"

RSpec.describe OrderPolicy do
  let(:band) { create(:band) }
  let(:order) { create(:order, :paid, band: band, stripe_checkout_session_id: "cs_1") }

  describe "#refund?" do
    it "allows an administrator of the order's band" do
      user = create(:user)
      create(:band_membership, :administrator, band: band, user: user)

      expect(described_class.new(user, order)).to be_refund
    end

    it "does not allow a plain band member" do
      user = create(:user)
      create(:band_membership, band: band, user: user)

      expect(described_class.new(user, order)).not_to be_refund
    end

    it "does not allow another band's administrator" do
      user = create(:user)
      create(:band_membership, :administrator, band: create(:band), user: user)

      expect(described_class.new(user, order)).not_to be_refund
    end

    it "does not allow the purchaser" do
      expect(described_class.new(order.user, order)).not_to be_refund
    end

    it "does not let a platform administrator act for the band" do
      expect(described_class.new(create(:user, :platform_admin), order)).not_to be_refund
    end

    it "does not allow an order whose payment is not refundable" do
      user = create(:user)
      create(:band_membership, :administrator, band: band, user: user)
      order.update!(status: :pending)

      expect(described_class.new(user, order)).not_to be_refund
    end
  end
end
