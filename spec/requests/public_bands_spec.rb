require "rails_helper"

RSpec.describe "Public band pages", type: :request do
  describe "GET /discover" do
    it "lists approved bands without authentication" do
      create(:band, :approved, name: "The Testers")

      get discover_bands_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("The Testers")
    end

    it "does not list pending, rejected, or suspended bands" do
      create(:band, name: "Pending Band")
      create(:band, :rejected, name: "Rejected Band")
      create(:band, :suspended, name: "Suspended Band")

      get discover_bands_path

      expect(response.body).not_to include("Pending Band")
      expect(response.body).not_to include("Rejected Band")
      expect(response.body).not_to include("Suspended Band")
    end

    it "links to each band's public page" do
      band = create(:band, :approved, name: "The Testers")

      get discover_bands_path

      expect(response.body).to include(public_band_path(band.slug))
    end

    it "features the most recently added band by default" do
      create(:band, :approved, name: "Older Band", created_at: 2.days.ago)
      create(:band, :approved, name: "Newer Band", created_at: 1.day.ago)

      get discover_bands_path

      body_without_footer = response.body.split("Older Band").first
      expect(body_without_footer).to include("Newer Band")
    end

    it "features the band with the most followers when sorted by followers" do
      popular = create(:band, :approved, name: "Popular Band")
      create_list(:follow, 3, band: popular)
      quiet = create(:band, :approved, name: "Quiet Band")

      get discover_bands_path(sort: "followers")

      body_without_footer = response.body.split("Quiet Band").first
      expect(body_without_footer).to include("Popular Band")
    end

    it "shows the featured band's follower count" do
      band = create(:band, :approved, name: "The Testers")
      create_list(:follow, 2, band: band)

      get discover_bands_path

      expect(response.body).to include("2 followers")
    end
  end

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

    it "shows the follower count" do
      band = create(:band, :approved)
      create_list(:follow, 2, band: band)

      get public_band_path(band.slug)

      expect(response.body).to include("2 followers")
    end

    it "does not show a follow button to an anonymous visitor" do
      band = create(:band, :approved)

      get public_band_path(band.slug)

      expect(response.body).not_to include(">Follow<")
    end

    it "shows a Follow button to an authenticated user who does not follow the band" do
      user = create(:user)
      band = create(:band, :approved)
      sign_in user

      get public_band_path(band.slug)

      expect(response.body).to include(">Follow<")
      expect(response.body).not_to include(">Following<")
    end

    it "shows a Following button to a user who already follows the band" do
      user = create(:user)
      band = create(:band, :approved)
      create(:follow, user: user, band: band)
      sign_in user

      get public_band_path(band.slug)

      expect(response.body).to include(">Following<")
    end

    it "shows a published public post to an anonymous visitor" do
      band = create(:band, :approved)
      create(:post, :published, band: band, title: "Public News")

      get public_band_path(band.slug)

      expect(response.body).to include("Public News")
    end

    it "does not show a draft post" do
      band = create(:band, :approved)
      create(:post, band: band, title: "Draft News")

      get public_band_path(band.slug)

      expect(response.body).not_to include("Draft News")
    end

    it "does not show a followers-only post to an anonymous visitor" do
      band = create(:band, :approved)
      create(:post, :published, :followers_only, band: band, title: "Followers News")

      get public_band_path(band.slug)

      expect(response.body).not_to include("Followers News")
    end

    it "does not show a followers-only post to an authenticated non-follower" do
      user = create(:user)
      band = create(:band, :approved)
      create(:post, :published, :followers_only, band: band, title: "Followers News")
      sign_in user

      get public_band_path(band.slug)

      expect(response.body).not_to include("Followers News")
    end

    it "shows a followers-only post to an authenticated follower" do
      user = create(:user)
      band = create(:band, :approved)
      create(:post, :published, :followers_only, band: band, title: "Followers News")
      create(:follow, user: user, band: band)
      sign_in user

      get public_band_path(band.slug)

      expect(response.body).to include("Followers News")
    end

    it "never shows a subscribers-only post, even to a follower" do
      user = create(:user)
      band = create(:band, :approved)
      create(:post, :published, :subscribers_only, band: band, title: "Subscribers News")
      create(:follow, user: user, band: band)
      sign_in user

      get public_band_path(band.slug)

      expect(response.body).not_to include("Subscribers News")
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
