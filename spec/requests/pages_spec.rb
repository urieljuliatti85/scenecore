require "rails_helper"

RSpec.describe "Pages", type: :request do
  describe "GET /" do
    it "is accessible without authentication" do
      get root_path

      expect(response).to have_http_status(:ok)
    end

    context "when there is no approved band" do
      it "shows sign in/up links when not authenticated" do
        get root_path

        expect(response.body).to include("Sign in")
        expect(response.body).to include("Sign up")
      end

      it "shows a link to the user's bands when authenticated" do
        user = create(:user)
        sign_in user

        get root_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Your bands")
      end

      it "shows a link to the public band directory when not authenticated" do
        get root_path

        expect(response.body).to include(discover_bands_path)
      end

      it "shows a link to the public band directory when authenticated" do
        user = create(:user)
        sign_in user

        get root_path

        expect(response.body).to include(discover_bands_path)
      end
    end

    context "when there is an approved band" do
      it "shows it as the featured band" do
        create(:band, :approved, name: "Farscape", description: "Thrash metal.")

        get root_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Featured Band")
        expect(response.body).to include("Farscape")
        expect(response.body).to include("Thrash metal.")
      end

      it "does not show a pending or rejected band as featured" do
        create(:band, name: "Pending Band")
        create(:band, :rejected, name: "Rejected Band")

        get root_path

        expect(response.body).not_to include("Featured Band")
      end

      it "shows the coming-soon navigation cards" do
        create(:band, :approved, name: "Farscape")

        get root_path

        expect(response.body).to include("Music")
        expect(response.body).to include("Exclusive Content")
        expect(response.body).to include("Subscriptions")
        expect(response.body).to include("Merchandise")
        expect(response.body).to include("Tickets")
      end

      it "shows social links when present" do
        create(:band, :approved, name: "Farscape", spotify_url: "https://open.spotify.com/artist/1")

        get root_path

        expect(response.body).to include("https://open.spotify.com/artist/1")
      end

      it "does not show social link icons when none are set" do
        create(:band, :approved, name: "Farscape")

        get root_path

        expect(response.body).not_to include("aria-label=\"Spotify\"")
      end

      it "shows up to 3 published albums from any approved band" do
        create(:band, :approved, name: "Farscape")
        band_two = create(:band, :approved, name: "Other Band")
        create(:album, :published, band: band_two, title: "Great Album")

        get root_path

        expect(response.body).to include("Feature Music Albums")
        expect(response.body).to include("Great Album")
        expect(response.body).to include("Other Band")
      end

      it "shows the album's Spotify cover thumbnail when no cover was uploaded" do
        band = create(:band, :approved, name: "Farscape")
        create(:album, :published, band: band, title: "Discovery", spotify_cover_url: "https://i.scdn.co/image/discovery-cover.jpg")

        get root_path

        expect(response.body).to include("https://i.scdn.co/image/discovery-cover.jpg")
      end

      it "does not show a draft album" do
        band = create(:band, :approved, name: "Farscape")
        create(:album, band: band, title: "Secret Album")

        get root_path

        expect(response.body).not_to include("Secret Album")
      end

      it "does not show a published album from a non-approved band" do
        create(:band, :approved, name: "Farscape")
        other_band = create(:band, name: "Pending Band Two")
        create(:album, :published, band: other_band, title: "Hidden Album")

        get root_path

        expect(response.body).not_to include("Hidden Album")
      end

      it "does not show the albums section when there are no published albums" do
        create(:band, :approved, name: "Farscape")

        get root_path

        expect(response.body).not_to include("Feature Music Albums")
      end
    end
  end
end
