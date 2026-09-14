require "rails_helper"

RSpec.describe "Tracks", type: :request do
  describe "GET /bands/:band_id/tracks/:id/edit" do
    it "requires authentication" do
      band = create(:band)
      album = create(:album, band: band)
      track = create(:track, album: album)

      get edit_band_track_path(band, track)

      expect(response).to redirect_to(new_user_session_path)
    end

    it "prevents a member of another band from viewing the edit form" do
      band = create(:band)
      album = create(:album, band: band)
      track = create(:track, album: album)
      outsider = create(:user)
      create(:band_membership, band: create(:band), user: outsider)
      sign_in outsider

      get edit_band_track_path(band, track)

      expect(response).to redirect_to(root_path)
    end

    it "returns 404 when the track belongs to a different band than the one in the URL" do
      band_a = create(:band)
      user = create(:user)
      create(:band_membership, :administrator, band: band_a, user: user)

      band_b = create(:band)
      album_b = create(:album, band: band_b)
      track_b = create(:track, album: album_b)
      sign_in user

      get edit_band_track_path(band_a, track_b)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PATCH /bands/:band_id/tracks/:id" do
    it "allows a band member to update a track's Spotify link" do
      user = create(:user)
      band = create(:band)
      create(:band_membership, band: band, user: user)
      album = create(:album, band: band)
      track = create(:track, album: album, spotify_url: nil)
      sign_in user

      patch band_track_path(band, track), params: { track: { spotify_url: "https://open.spotify.com/track/4uLU6hMCjMI75M1A2tKUQC" } }

      expect(track.reload.spotify_url).to eq("https://open.spotify.com/track/4uLU6hMCjMI75M1A2tKUQC")
      expect(response).to redirect_to(band_path(band))
    end

    it "rejects a non-Spotify URL" do
      user = create(:user)
      band = create(:band)
      create(:band_membership, band: band, user: user)
      album = create(:album, band: band)
      track = create(:track, album: album, spotify_url: nil)
      sign_in user

      patch band_track_path(band, track), params: { track: { spotify_url: "https://example.com/song" } }

      expect(track.reload.spotify_url).to be_nil
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "requires authentication" do
      band = create(:band)
      album = create(:album, band: band)
      track = create(:track, album: album)

      patch band_track_path(band, track), params: { track: { spotify_url: "https://open.spotify.com/track/4uLU6hMCjMI75M1A2tKUQC" } }

      expect(response).to redirect_to(new_user_session_path)
    end

    it "prevents a member of another band from updating the track" do
      band = create(:band)
      album = create(:album, band: band)
      track = create(:track, album: album, spotify_url: nil)
      outsider = create(:user)
      create(:band_membership, band: create(:band), user: outsider)
      sign_in outsider

      patch band_track_path(band, track), params: { track: { spotify_url: "https://open.spotify.com/track/4uLU6hMCjMI75M1A2tKUQC" } }

      expect(track.reload.spotify_url).to be_nil
      expect(response).to redirect_to(root_path)
    end

    it "returns 404 when the track belongs to a different band than the one in the URL" do
      band_a = create(:band)
      user = create(:user)
      create(:band_membership, :administrator, band: band_a, user: user)

      band_b = create(:band)
      album_b = create(:album, band: band_b)
      track_b = create(:track, album: album_b, spotify_url: nil)
      sign_in user

      patch band_track_path(band_a, track_b), params: { track: { spotify_url: "https://open.spotify.com/track/4uLU6hMCjMI75M1A2tKUQC" } }

      expect(response).to have_http_status(:not_found)
      expect(track_b.reload.spotify_url).to be_nil
    end
  end
end
