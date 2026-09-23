require "rails_helper"

RSpec.describe "Band Admin shipping zones", type: :request do
  let(:band) { create(:band, :approved) }
  let(:admin) { create(:user) }

  before { create(:band_membership, :administrator, band: band, user: admin) }

  describe "authorization" do
    it "denies a signed-out visitor" do
      get band_shipping_zones_path(band)

      expect(response).to redirect_to(new_user_session_path)
    end

    it "denies a fan" do
      sign_in create(:user)

      get band_shipping_zones_path(band)

      expect(response).to redirect_to(root_path)
    end

    # Rates decide what the band charges and where it sells, so they are
    # administrator work — the same bar as the products they apply to.
    it "denies a plain band member" do
      member = create(:user)
      create(:band_membership, :member, band: band, user: member)
      sign_in member

      get band_shipping_zones_path(band)

      expect(response).to redirect_to(root_path)
    end

    it "denies an administrator of another band" do
      other_admin = create(:user)
      create(:band_membership, :administrator, band: create(:band, :approved), user: other_admin)
      sign_in other_admin

      get band_shipping_zones_path(band)

      expect(response).to redirect_to(root_path)
    end

    it "denies a platform administrator without a membership in the band" do
      sign_in create(:user, :platform_admin)

      get band_shipping_zones_path(band)

      expect(response).to redirect_to(root_path)
    end

    it "allows the band's administrator" do
      sign_in admin

      get band_shipping_zones_path(band)

      expect(response).to have_http_status(:ok)
    end
  end

  describe "creating a destination" do
    before { sign_in admin }

    it "saves the zone with its countries" do
      expect {
        post band_shipping_zones_path(band), params: {
          shipping_zone: { name: "South America", shipping_cents: 2_500, country_codes: [ "BR", "AR", "CL" ] }
        }
      }.to change(ShippingZone, :count).by(1)

      zone = band.shipping_zones.sole
      expect(zone.name).to eq("South America")
      expect(zone.shipping_cents).to eq(2_500)
      expect(zone.country_codes).to contain_exactly("BR", "AR", "CL")
    end

    it "accepts free shipping" do
      post band_shipping_zones_path(band), params: {
        shipping_zone: { name: "Local", shipping_cents: 0, country_codes: [ "BR" ] }
      }

      expect(band.shipping_zones.sole.shipping_cents).to eq(0)
    end

    it "refuses a zone with no countries" do
      expect {
        post band_shipping_zones_path(band), params: {
          shipping_zone: { name: "Nowhere", shipping_cents: 1_000, country_codes: [] }
        }
      }.not_to change(ShippingZone, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("Pick at least one country")
    end

    it "ignores a code that is not a country" do
      post band_shipping_zones_path(band), params: {
        shipping_zone: { name: "Brazil", shipping_cents: 1_000, country_codes: [ "BR", "ZZ" ] }
      }

      expect(band.shipping_zones.sole.country_codes).to eq([ "BR" ])
    end

    # Two zones claiming one country would make that destination's rate
    # depend on join order, so the clash is reported as a form error naming
    # the zone that already has it.
    it "refuses a country already served by another zone" do
      create(:shipping_zone, band: band, name: "Brazil", country_codes: [ "BR" ])

      expect {
        post band_shipping_zones_path(band), params: {
          shipping_zone: { name: "Mercosur", shipping_cents: 3_000, country_codes: [ "BR", "AR" ] }
        }
      }.not_to change(ShippingZone, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("Brazil is already in Brazil")
    end

    it "leaves no half-saved zone behind when the countries clash" do
      create(:shipping_zone, band: band, name: "Brazil", country_codes: [ "BR" ])

      post band_shipping_zones_path(band), params: {
        shipping_zone: { name: "Mercosur", shipping_cents: 3_000, country_codes: [ "BR" ] }
      }

      expect(band.shipping_zones.pluck(:name)).to eq([ "Brazil" ])
      expect(band.shipping_zone_countries.count).to eq(1)
    end

    it "does not let one band add a destination to another" do
      other_band = create(:band, :approved)

      expect {
        post band_shipping_zones_path(other_band), params: {
          shipping_zone: { name: "Anywhere", shipping_cents: 100, country_codes: [ "BR" ] }
        }
      }.not_to change(ShippingZone, :count)

      expect(response).to redirect_to(root_path)
    end
  end

  describe "updating a destination" do
    let!(:zone) { create(:shipping_zone, band: band, name: "Brazil", shipping_cents: 1_500, country_codes: [ "BR" ]) }

    before { sign_in admin }

    it "replaces the country set rather than adding to it" do
      patch band_shipping_zone_path(band, zone), params: {
        shipping_zone: { name: "Brazil", shipping_cents: 1_500, country_codes: [ "AR", "CL" ] }
      }

      expect(zone.reload.country_codes).to contain_exactly("AR", "CL")
    end

    it "keeps a country the zone already holds" do
      patch band_shipping_zone_path(band, zone), params: {
        shipping_zone: { name: "Brazil", shipping_cents: 2_000, country_codes: [ "BR", "AR" ] }
      }

      expect(zone.reload.country_codes).to contain_exactly("BR", "AR")
      expect(zone.shipping_cents).to eq(2_000)
    end

    # Zones are looked up through the band in the URL, so a zone id from
    # elsewhere is not found rather than merely unauthorized. Tested with
    # someone who administers both bands, because a policy check alone
    # would pass for them and let this band's URL edit the other's rates.
    it "cannot reach another band's zone, even for an administrator of both" do
      other_band = create(:band, :approved)
      create(:band_membership, :administrator, band: other_band, user: admin)
      foreign = create(:shipping_zone, band: other_band,
                                       name: "Japan", shipping_cents: 5_000, country_codes: [ "JP" ])

      patch band_shipping_zone_path(band, foreign), params: {
        shipping_zone: { name: "Hijacked", shipping_cents: 1, country_codes: [ "JP" ] }
      }

      expect(foreign.reload.name).to eq("Japan")
      expect(foreign.shipping_cents).to eq(5_000)
    end
  end

  describe "deleting a destination" do
    let!(:zone) { create(:shipping_zone, band: band, country_codes: [ "BR", "AR" ]) }

    before { sign_in admin }

    it "removes the zone and its countries" do
      expect { delete band_shipping_zone_path(band, zone) }
        .to change(ShippingZone, :count).by(-1)
        .and change(ShippingZoneCountry, :count).by(-2)
    end

    it "denies a fan" do
      sign_in create(:user)

      expect { delete band_shipping_zone_path(band, zone) }.not_to change(ShippingZone, :count)
      expect(response).to redirect_to(root_path)
    end
  end
end
