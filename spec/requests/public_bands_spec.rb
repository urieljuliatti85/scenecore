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

    it "shows only published albums and tracks" do
      band = create(:band, :approved)
      published_album = create(:album, :published, band: band, title: "Public Album")
      draft_album = create(:album, band: band, title: "Secret Album")
      create(:track, :published, album: published_album, title: "Public Track")
      create(:track, album: published_album, title: "Secret Track")

      get public_band_path(band.slug)

      expect(response.body).to include("Public Album")
      expect(response.body).not_to include("Secret Album")
      expect(response.body).to include("Public Track")
      expect(response.body).not_to include("Secret Track")
    end

    it "does not show anything when the band has no published albums" do
      band = create(:band, :approved)
      create(:album, band: band, title: "Secret Album")

      get public_band_path(band.slug)

      expect(response.body).not_to include("Secret Album")
    end

    it "shows the Spotify embed player for a published track with a Spotify link" do
      band = create(:band, :approved)
      album = create(:album, :published, band: band)
      create(:track, :published, album: album, spotify_url: "https://open.spotify.com/track/4uLU6hMCjMI75M1A2tKUQC")

      get public_band_path(band.slug)

      expect(response.body).to include("https://open.spotify.com/embed/track/4uLU6hMCjMI75M1A2tKUQC")
    end

    it "does not show an embed player for a track without a Spotify link" do
      band = create(:band, :approved)
      album = create(:album, :published, band: band)
      create(:track, :published, album: album, spotify_url: nil, title: "No Link Track")

      get public_band_path(band.slug)

      expect(response.body).to include("No Link Track")
      expect(response.body).not_to include("open.spotify.com/embed")
    end

    it "does not leak a draft track's Spotify link, even inside a published album" do
      band = create(:band, :approved)
      album = create(:album, :published, band: band)
      create(:track, album: album, title: "Secret Track", spotify_url: "https://open.spotify.com/track/4uLU6hMCjMI75M1A2tKUQC")

      get public_band_path(band.slug)

      expect(response.body).not_to include("Secret Track")
      expect(response.body).not_to include("4uLU6hMCjMI75M1A2tKUQC")
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
