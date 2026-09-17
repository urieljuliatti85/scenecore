require "rails_helper"

RSpec.describe ShippingZone, type: :model do
  let(:band) { create(:band, :approved) }

  it "requires a name unique within the band" do
    create(:shipping_zone, band: band, name: "Brazil", country_codes: [ "BR" ])
    duplicate = build(:shipping_zone, band: band, name: "brazil", country_codes: [ "AR" ])

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:name]).to be_present
  end

  it "lets two bands use the same zone name" do
    create(:shipping_zone, band: band, name: "Brazil", country_codes: [ "BR" ])
    other = build(:shipping_zone, band: create(:band, :approved), name: "Brazil", country_codes: [ "BR" ])

    expect(other).to be_valid
  end

  it "rejects a negative rate" do
    expect(build(:shipping_zone, shipping_cents: -1)).not_to be_valid
  end

  it "allows free shipping" do
    expect(build(:shipping_zone, shipping_cents: 0)).to be_valid
  end

  describe ".serving" do
    let!(:domestic) { create(:shipping_zone, band: band, name: "Brazil", country_codes: [ "BR" ]) }
    let!(:abroad) { create(:shipping_zone, band: band, name: "Europe", country_codes: [ "PT", "ES" ]) }

    it "finds the zone holding a country" do
      expect(band.shipping_zones.serving("ES")).to contain_exactly(abroad)
    end

    it "matches regardless of how the code is cased or padded" do
      expect(band.shipping_zones.serving(" br ")).to contain_exactly(domestic)
    end

    it "finds nothing for a country the band does not serve" do
      expect(band.shipping_zones.serving("JP")).to be_empty
    end

    it "does not leak another band's zones" do
      other_band = create(:band, :approved)
      create(:shipping_zone, band: other_band, name: "Japan", country_codes: [ "JP" ])

      expect(band.shipping_zones.serving("JP")).to be_empty
    end
  end

  it "names its countries in full" do
    zone = create(:shipping_zone, band: band, country_codes: [ "PT", "BR" ])

    expect(zone.country_names).to eq([ "Brazil", "Portugal" ])
  end

  it "removes its countries when deleted" do
    zone = create(:shipping_zone, band: band, country_codes: [ "BR", "AR" ])

    expect { zone.destroy! }.to change(ShippingZoneCountry, :count).by(-2)
  end
end
