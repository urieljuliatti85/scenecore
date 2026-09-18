require "rails_helper"

RSpec.describe MerchDiscount, type: :model do
  it "is valid with valid attributes" do
    expect(build(:merch_discount)).to be_valid
  end

  it "requires a band" do
    expect(build(:merch_discount, band: nil)).not_to be_valid
  end

  it "restricts level to fan, supporter, or core_member" do
    discount = build(:merch_discount)
    discount.level = "vip"

    expect(discount).not_to be_valid
  end

  it "rejects a percentage below 0" do
    expect(build(:merch_discount, percentage: -1)).not_to be_valid
  end

  it "rejects a percentage above 100" do
    expect(build(:merch_discount, percentage: 101)).not_to be_valid
  end

  it "accepts 0 and 100 as boundary values" do
    expect(build(:merch_discount, percentage: 0)).to be_valid
    expect(build(:merch_discount, percentage: 100)).to be_valid
  end

  it "only allows one discount per level per band" do
    band = create(:band)
    create(:merch_discount, band: band, level: :fan)

    expect(build(:merch_discount, band: band, level: :fan)).not_to be_valid
  end

  it "allows the same level for different bands" do
    create(:merch_discount, band: create(:band), level: :fan)

    expect(build(:merch_discount, band: create(:band), level: :fan)).to be_valid
  end

  it "allows different levels for the same band" do
    band = create(:band)
    create(:merch_discount, band: band, level: :fan)

    expect(build(:merch_discount, band: band, level: :supporter)).to be_valid
  end

  describe ".percentage_for" do
    it "returns the highest discount available through the member's level" do
      band = create(:band)
      create(:merch_discount, band: band, level: :fan, percentage: 5)
      create(:merch_discount, band: band, level: :supporter, percentage: 10)
      core_member = create(:membership, :core_member, band: band)

      expect(described_class.percentage_for(core_member)).to eq(10)
    end

    it "returns zero for an inactive membership" do
      membership = create(:membership, :cancelled)
      create(:merch_discount, band: membership.band, level: :fan, percentage: 10)

      expect(described_class.percentage_for(membership)).to eq(0)
    end
  end
end
