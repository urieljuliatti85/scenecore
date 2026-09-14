require "rails_helper"

RSpec.describe "Admin::Bands", type: :request do
  describe "GET /admin/bands" do
    it "lists all bands for a platform admin" do
      admin = create(:user, :platform_admin)
      pending_band = create(:band, name: "Pending Band")
      approved_band = create(:band, :approved, name: "Approved Band")
      sign_in admin

      get admin_bands_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Pending Band")
      expect(response.body).to include("Approved Band")
    end

    it "filters by status" do
      admin = create(:user, :platform_admin)
      create(:band, name: "Pending Band")
      create(:band, :approved, name: "Approved Band")
      sign_in admin

      get admin_bands_path(status: "approved")

      expect(response.body).to include("Approved Band")
      expect(response.body).not_to include("Pending Band")
    end

    it "returns 404 for a regular authenticated user" do
      user = create(:user)
      sign_in user

      get admin_bands_path

      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 for a band administrator who is not a platform admin" do
      user = create(:user)
      band = create(:band)
      create(:band_membership, :administrator, band: band, user: user)
      sign_in user

      get admin_bands_path

      expect(response).to have_http_status(:not_found)
    end

    it "requires authentication" do
      get admin_bands_path

      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
