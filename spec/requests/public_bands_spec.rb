require "rails_helper"

RSpec.describe "Public band pages", type: :request do
  describe "GET /:slug" do
    it "shows an approved band's public page without authentication" do
      band = create(:band, :approved, name: "The Testers", description: "A great band.")

      get public_band_path(band.slug)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("The Testers")
      expect(response.body).to include("A great band.")
    end

    it "returns 404 for a pending band" do
      band = create(:band, name: "Pending Band")

      get public_band_path(band.slug)

      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 for a rejected band" do
      band = create(:band, :rejected, name: "Rejected Band")

      get public_band_path(band.slug)

      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 for a nonexistent slug" do
      get public_band_path("no-such-band")

      expect(response).to have_http_status(:not_found)
    end

    it "shows the coming-soon navigation cards" do
      band = create(:band, :approved, name: "The Testers")

      get public_band_path(band.slug)

      expect(response.body).to include("Music")
      expect(response.body).to include("Tickets")
    end

    it "shows social links when present" do
      band = create(:band, :approved, name: "The Testers", website_url: "https://the-testers.example.com")

      get public_band_path(band.slug)

      expect(response.body).to include("https://the-testers.example.com")
    end

    it "does not show social link icons when none are set" do
      band = create(:band, :approved, name: "The Testers")

      get public_band_path(band.slug)

      expect(response.body).not_to include("aria-label=\"Website\"")
    end
  end

  describe "route precedence" do
    it "does not shadow the management area routes" do
      get bands_path

      expect(response).to redirect_to(new_user_session_path)
    end

    it "does not shadow the profile route" do
      get profile_path

      expect(response).to redirect_to(new_user_session_path)
    end

    it "does not shadow the root route" do
      get root_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("SceneCore")
    end
  end
end
