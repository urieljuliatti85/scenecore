require "rails_helper"

RSpec.describe ProductShippingRate, type: :model do
  let(:band) { create(:band, :approved) }
  let(:product) { create(:product, band: band) }
  let(:zone) { create(:shipping_zone, band: band, country_codes: [ "BR" ]) }

  it "overrides a zone for one product" do
    expect(build(:product_shipping_rate, product: product, shipping_zone: zone)).to be_valid
  end

  it "rejects a negative rate" do
    expect(build(:product_shipping_rate, product: product, shipping_zone: zone, shipping_cents: -1)).not_to be_valid
  end

  it "allows free shipping as a deliberate override" do
    expect(build(:product_shipping_rate, product: product, shipping_zone: zone, shipping_cents: 0)).to be_valid
  end

  it "holds one rate per zone per product" do
    create(:product_shipping_rate, product: product, shipping_zone: zone)

    expect(build(:product_shipping_rate, product: product, shipping_zone: zone)).not_to be_valid
  end

  # A product must not be priced against another band's zone — that would
  # let one band's rates decide another band's shipping.
  it "refuses a zone belonging to a different band" do
    foreign = create(:shipping_zone, band: create(:band, :approved), country_codes: [ "JP" ])
    rate = build(:product_shipping_rate, product: product, shipping_zone: foreign)

    expect(rate).not_to be_valid
    expect(rate.errors[:shipping_zone]).to include("must belong to the same band as the product")
  end
end
