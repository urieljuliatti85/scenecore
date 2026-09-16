require "rails_helper"

RSpec.describe BandMembershipPrice, type: :model do
  it "is valid with valid attributes" do
    expect(build(:band_membership_price)).to be_valid
  end

  it "requires a band" do
    price = build(:band_membership_price, band: nil)

    expect(price).not_to be_valid
  end

  it "restricts level to fan, supporter, or core_member" do
    price = build(:band_membership_price)
    price.level = "vip"

    expect(price).not_to be_valid
  end

  it "requires a stripe_product_id" do
    price = build(:band_membership_price, stripe_product_id: nil)

    expect(price).not_to be_valid
  end

  it "requires a stripe_price_id" do
    price = build(:band_membership_price, stripe_price_id: nil)

    expect(price).not_to be_valid
  end

  it "only allows one price per band per level" do
    band = create(:band)
    create(:band_membership_price, band: band, level: :fan)

    duplicate = build(:band_membership_price, band: band, level: :fan)

    expect(duplicate).not_to be_valid
  end

  it "allows the same band to have prices for different levels" do
    band = create(:band)
    create(:band_membership_price, band: band, level: :fan)

    other_level = build(:band_membership_price, band: band, level: :supporter)

    expect(other_level).to be_valid
  end
end
