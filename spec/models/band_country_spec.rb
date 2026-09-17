require "rails_helper"

RSpec.describe Band, "country code" do
  it "defaults existing and new bands to Brazil" do
    expect(Band.new.country_code).to eq("BR")
  end

  it "normalizes a two-letter country code to uppercase" do
    band = build(:band, country_code: " pt ")

    expect(band).to be_valid
    expect(band.country_code).to eq("PT")
  end

  it "rejects an invalid country code" do
    band = build(:band, country_code: "BRA")

    expect(band).not_to be_valid
    expect(band.errors[:country_code]).to include("must be a two-letter ISO country code")
  end
end
