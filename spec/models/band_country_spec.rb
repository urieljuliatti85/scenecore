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

  it "cannot change country after Stripe Connect setup has started" do
    band = create(:band, country_code: "BR", stripe_connect_account_id: "acct_existing")

    expect(band.update(country_code: "US")).to be(false)
    expect(band.errors[:country_code]).to include("cannot be changed after Stripe Connect setup has started")
    expect(band.reload.country_code).to eq("BR")
  end
end
