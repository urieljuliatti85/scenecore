require "rails_helper"

RSpec.describe "Tracks", type: :request do
  describe "GET /bands/:band_id/tracks/new" do
    it "requires authentication" do
      band = create(:band)

      get new_band_track_path(band)

      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "POST /bands/:band_id/tracks" do
    it "allows a band administrator to create a track" do
      user = create(:user)
      band = create(:band)
      create(:band_membership, :administrator, band: band, user: user)
      sign_in user

      expect {
        post band_tracks_path(band), params: { track: { title: "New Song" } }
      }.to change(Track, :count).by(1)

      track = Track.last
      expect(track.title).to eq("New Song")
      expect(track.band).to eq(band)
      expect(track.status).to eq("draft")
      expect(response).to redirect_to(band_path(band))
    end

    it "allows a plain band member (not administrator) to create a track" do
      user = create(:user)
      band = create(:band)
      create(:band_membership, band: band, user: user)
      sign_in user

      expect {
        post band_tracks_path(band), params: { track: { title: "New Song" } }
      }.to change(Track, :count).by(1)
    end

    it "does not create a track with a blank title" do
      user = create(:user)
      band = create(:band)
      create(:band_membership, :administrator, band: band, user: user)
      sign_in user

      expect {
        post band_tracks_path(band), params: { track: { title: "" } }
      }.not_to change(Track, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "requires authentication" do
      band = create(:band)

      expect {
        post band_tracks_path(band), params: { track: { title: "New Song" } }
      }.not_to change(Track, :count)

      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "band isolation" do
    it "prevents a member of one band from creating a track for another band" do
      band_a_member = create(:user)
      band_a = create(:band)
      create(:band_membership, band: band_a, user: band_a_member)

      band_b = create(:band)

      sign_in band_a_member

      expect {
        post band_tracks_path(band_b), params: { track: { title: "Hijacked Song" } }
      }.not_to change(Track, :count)
    end
  end

  describe "GET /bands/:band_id/tracks/:id/edit" do
    it "requires authentication" do
      band = create(:band)
      track = create(:track, band: band)

      get edit_band_track_path(band, track)

      expect(response).to redirect_to(new_user_session_path)
    end

    it "prevents a member of another band from viewing the edit form" do
      band = create(:band)
      track = create(:track, band: band)
      outsider = create(:user)
      create(:band_membership, band: create(:band), user: outsider)
      sign_in outsider

      get edit_band_track_path(band, track)

      expect(response).to redirect_to(root_path)
    end
  end

  describe "PATCH /bands/:band_id/tracks/:id" do
    it "allows a band member to add a Spotify link to a track" do
      user = create(:user)
      band = create(:band)
      create(:band_membership, band: band, user: user)
      track = create(:track, band: band, spotify_url: nil)
      sign_in user

      patch band_track_path(band, track), params: { track: { spotify_url: "https://open.spotify.com/track/4uLU6hMCjMI75M1A2tKUQC" } }

      expect(track.reload.spotify_url).to eq("https://open.spotify.com/track/4uLU6hMCjMI75M1A2tKUQC")
      expect(response).to redirect_to(band_path(band))
    end

    it "rejects a non-Spotify URL" do
      user = create(:user)
      band = create(:band)
      create(:band_membership, band: band, user: user)
      track = create(:track, band: band, spotify_url: nil)
      sign_in user

      patch band_track_path(band, track), params: { track: { spotify_url: "https://example.com/song" } }

      expect(track.reload.spotify_url).to be_nil
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "requires authentication" do
      band = create(:band)
      track = create(:track, band: band)

      patch band_track_path(band, track), params: { track: { spotify_url: "https://open.spotify.com/track/4uLU6hMCjMI75M1A2tKUQC" } }

      expect(response).to redirect_to(new_user_session_path)
    end

    it "prevents a member of another band from updating the track" do
      band = create(:band)
      track = create(:track, band: band, spotify_url: nil)
      outsider = create(:user)
      create(:band_membership, band: create(:band), user: outsider)
      sign_in outsider

      patch band_track_path(band, track), params: { track: { spotify_url: "https://open.spotify.com/track/4uLU6hMCjMI75M1A2tKUQC" } }

      expect(track.reload.spotify_url).to be_nil
      expect(response).to redirect_to(root_path)
    end
  end
end
