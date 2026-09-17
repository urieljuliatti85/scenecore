require "rails_helper"

RSpec.describe "Band country", type: :request do
  it "stores the country selected when a band is created" do
    user = create(:user)
    sign_in user

    post bands_path, params: { band: { name: "Lisbon Noise", country_code: "PT" } }

    expect(Band.last.country_code).to eq("PT")
  end

  it "lets a band administrator change the band's country before Connect starts" do
    user = create(:user)
    band = create(:band, country_code: "BR")
    create(:band_membership, :administrator, band: band, user: user)
    sign_in user

    patch band_path(band), params: { band: { country_code: "US" } }

    expect(band.reload.country_code).to eq("US")
  end

  it "does not change country after Connect has started" do
    user = create(:user)
    band = create(:band, country_code: "BR", stripe_connect_account_id: "acct_existing")
    create(:band_membership, :administrator, band: band, user: user)
    sign_in user

    patch band_path(band), params: { band: { country_code: "US" } }

    expect(response).to have_http_status(:unprocessable_content)
    expect(band.reload.country_code).to eq("BR")
  end
end
