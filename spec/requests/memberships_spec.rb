require "rails_helper"

RSpec.describe "Memberships", type: :request do
  describe "GET /bands/:band_id/supporters" do
    it "allows a band administrator to list the band's memberships" do
      band = create(:band)
      admin = create(:user)
      create(:band_membership, :administrator, band: band, user: admin)
      supporter = create(:membership, :supporter, band: band)
      sign_in admin

      get band_memberships_path(band)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(supporter.user.name)
    end

    it "allows a platform administrator to list any band's memberships" do
      band = create(:band)
      platform_admin = create(:user, :platform_admin)
      create(:membership, band: band)
      sign_in platform_admin

      get band_memberships_path(band)

      expect(response).to have_http_status(:ok)
    end

    it "does not allow a plain band member to list memberships" do
      band = create(:band)
      member = create(:user)
      create(:band_membership, band: band, user: member)
      sign_in member

      get band_memberships_path(band)

      expect(response).to redirect_to(root_path)
    end

    it "does not allow an administrator of a different band" do
      band = create(:band)
      admin = create(:user)
      create(:band_membership, :administrator, band: create(:band), user: admin)
      sign_in admin

      get band_memberships_path(band)

      expect(response).to redirect_to(root_path)
    end

    it "does not allow an unrelated user" do
      band = create(:band)
      outsider = create(:user)
      sign_in outsider

      get band_memberships_path(band)

      expect(response).to redirect_to(root_path)
    end

    it "does not leak another band's memberships" do
      band = create(:band)
      other_band = create(:band)
      admin = create(:user)
      create(:band_membership, :administrator, band: band, user: admin)
      other_bands_supporter = create(:membership, :supporter, band: other_band)
      sign_in admin

      get band_memberships_path(band)

      expect(response.body).not_to include(other_bands_supporter.user.name)
    end
  end
end
