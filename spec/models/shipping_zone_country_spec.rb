require "rails_helper"

RSpec.describe ShippingZoneCountry, type: :model do
  let(:band) { create(:band, :approved) }
  let(:zone) { create(:shipping_zone, band: band, name: "Brazil", country_codes: [ "BR" ]) }

  it "normalizes the code to upper case" do
    record = zone.zone_countries.create!(band: band, country_code: " ar ")

    expect(record.country_code).to eq("AR")
  end

  it "rejects a code that is not a country" do
    record = zone.zone_countries.build(band: band, country_code: "ZZ")

    expect(record).not_to be_valid
    expect(record.errors[:country_code]).to include("is not a recognised country")
  end

  # A country in two of a band's zones would make the rate for that
  # destination depend on join order, so it is barred in the model and by a
  # unique index.
  it "refuses a country already in another zone of the same band" do
    zone # the zone holding BR has to exist before the clash can happen
    other = create(:shipping_zone, band: band, name: "Elsewhere", country_codes: [])
    record = other.zone_countries.build(band: band, country_code: "BR")

    expect(record).not_to be_valid
    expect(record.errors[:country_code]).to include("is already in another zone")
  end

  it "allows the same country for a different band" do
    other_band = create(:band, :approved)
    other_zone = create(:shipping_zone, band: other_band, name: "Brazil", country_codes: [])

    expect(other_zone.zone_countries.build(band: other_band, country_code: "BR")).to be_valid
  end

  it "takes its band from the zone" do
    record = zone.zone_countries.create!(country_code: "AR")

    expect(record.band).to eq(band)
  end

  it "is enforced by the database, not only the model" do
    zone.zone_countries.create!(band: band, country_code: "AR")
    other = create(:shipping_zone, band: band, name: "Elsewhere", country_codes: [])
    duplicate = described_class.new(shipping_zone: other, band: band, country_code: "AR")

    expect { duplicate.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
  end
end
