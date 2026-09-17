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
end
