require "rails_helper"

RSpec.describe "Albums", type: :request do
  describe "GET /bands/:band_id/albums/new" do
    it "requires authentication" do
      band = create(:band)

      get new_band_album_path(band)

      expect(response).to redirect_to(new_user_session_path)
    end

    it "prevents a member of another band from viewing the form" do
      band = create(:band)
      outsider = create(:user)
      create(:band_membership, band: create(:band), user: outsider)
      sign_in outsider

      get new_band_album_path(band)

      expect(response).to redirect_to(root_path)
    end
  end

  describe "GET /bands/:band_id/albums/search" do
    it "requires authentication" do
      band = create(:band)

      get search_band_albums_path(band), params: { q: "Discovery" }

      expect(response).to redirect_to(new_user_session_path)
    end

    it "returns matching albums as JSON for a band member" do
      user = create(:user)
      band = create(:band)
      create(:band_membership, band: band, user: user)
      sign_in user

      result = SpotifyClient::AlbumResult.new(spotify_id: "4uLU6hMCjMI75M1A2tKUQC", name: "Discovery", artist: "Daft Punk", image_url: "https://example.com/cover.jpg", release_year: "2001")
      allow_any_instance_of(SpotifyClient).to receive(:search_albums).with("Discovery").and_return([ result ])

      get search_band_albums_path(band), params: { q: "Discovery" }

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body.first["spotify_id"]).to eq("4uLU6hMCjMI75M1A2tKUQC")
      expect(body.first["name"]).to eq("Discovery")
    end

    it "prevents a member of another band from searching" do
      band = create(:band)
      outsider = create(:user)
      create(:band_membership, band: create(:band), user: outsider)
      sign_in outsider

      get search_band_albums_path(band), params: { q: "Discovery" }

      expect(response).to redirect_to(root_path)
    end
  end

  describe "POST /bands/:band_id/albums" do
    let(:fetched_album) do
      SpotifyClient::AlbumDetails.new(
        name: "Discovery",
        cover_image_url: "https://i.scdn.co/image/discovery-cover.jpg",
        tracks: [
          SpotifyClient::TrackDetails.new(title: "One More Time", track_number: 1, spotify_url: "https://open.spotify.com/track/0DiWol3AO6WpXZgp0goxAV"),
          SpotifyClient::TrackDetails.new(title: "Aerodynamic", track_number: 2, spotify_url: "https://open.spotify.com/track/2xLMifQCjDGFmkHkpNLD9h")
        ]
      )
    end

    it "imports the album and its tracks for a band member" do
      user = create(:user)
      band = create(:band)
      create(:band_membership, band: band, user: user)
      sign_in user
      allow_any_instance_of(SpotifyClient).to receive(:fetch_album).with("4uLU6hMCjMI75M1A2tKUQC").and_return(fetched_album)

      expect {
        post band_albums_path(band), params: { spotify_album_id: "4uLU6hMCjMI75M1A2tKUQC" }
      }.to change(Album, :count).by(1).and change(Track, :count).by(2)

      album = Album.last
      expect(album.title).to eq("Discovery")
      expect(album.band).to eq(band)
      expect(album.spotify_cover_url).to eq("https://i.scdn.co/image/discovery-cover.jpg")
      expect(album.tracks.order(:track_number).pluck(:title)).to eq([ "One More Time", "Aerodynamic" ])
      expect(response).to redirect_to(band_path(band))
    end

    it "does not create anything when no album is selected" do
      user = create(:user)
      band = create(:band)
      create(:band_membership, band: band, user: user)
      sign_in user

      expect {
        post band_albums_path(band), params: { spotify_album_id: "" }
      }.not_to change(Album, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "does not create anything when the Spotify album id has an invalid format" do
      user = create(:user)
      band = create(:band)
      create(:band_membership, band: band, user: user)
      sign_in user

      expect {
        post band_albums_path(band), params: { spotify_album_id: "../../etc/passwd" }
      }.not_to change(Album, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "does not create anything when Spotify import fails" do
      user = create(:user)
      band = create(:band)
      create(:band_membership, band: band, user: user)
      sign_in user
      allow_any_instance_of(SpotifyClient).to receive(:fetch_album).and_raise(SpotifyClient::Error)

      expect {
        post band_albums_path(band), params: { spotify_album_id: "4uLU6hMCjMI75M1A2tKUQC" }
      }.not_to change(Album, :count)

      expect(response).to have_http_status(:bad_gateway)
    end

    it "requires authentication" do
      band = create(:band)

      expect {
        post band_albums_path(band), params: { spotify_album_id: "4uLU6hMCjMI75M1A2tKUQC" }
      }.not_to change(Album, :count)

      expect(response).to redirect_to(new_user_session_path)
    end

    it "prevents a member of another band from importing an album" do
      band = create(:band)
      outsider = create(:user)
      create(:band_membership, band: create(:band), user: outsider)
      sign_in outsider

      expect {
        post band_albums_path(band), params: { spotify_album_id: "4uLU6hMCjMI75M1A2tKUQC" }
      }.not_to change(Album, :count)

      expect(response).to redirect_to(root_path)
    end
  end

  describe "PATCH /bands/:band_id/albums/:id/publish" do
    it "publishes the album and every track that has a Spotify link" do
      user = create(:user)
      band = create(:band)
      create(:band_membership, band: band, user: user)
      album = create(:album, band: band)
      linked_track = create(:track, album: album, spotify_url: "https://open.spotify.com/track/4uLU6hMCjMI75M1A2tKUQC")
      unlinked_track = create(:track, album: album, spotify_url: nil)
      sign_in user

      patch publish_band_album_path(band, album)

      expect(album.reload.status).to eq("published")
      expect(linked_track.reload.status).to eq("published")
      expect(unlinked_track.reload.status).to eq("draft")
      expect(response).to redirect_to(band_path(band))
    end

    it "requires authentication" do
      band = create(:band)
      album = create(:album, band: band)

      patch publish_band_album_path(band, album)

      expect(album.reload.status).to eq("draft")
      expect(response).to redirect_to(new_user_session_path)
    end

    it "prevents a member of another band from publishing the album" do
      band = create(:band)
      album = create(:album, band: band)
      outsider = create(:user)
      create(:band_membership, band: create(:band), user: outsider)
      sign_in outsider

      patch publish_band_album_path(band, album)

      expect(album.reload.status).to eq("draft")
      expect(response).to redirect_to(root_path)
    end
  end

  describe "PATCH /bands/:band_id/albums/:id/unpublish" do
    it "reverts the album and all of its tracks to draft" do
      user = create(:user)
      band = create(:band)
      create(:band_membership, band: band, user: user)
      album = create(:album, :published, band: band)
      track = create(:track, :published, album: album)
      sign_in user

      patch unpublish_band_album_path(band, album)

      expect(album.reload.status).to eq("draft")
      expect(track.reload.status).to eq("draft")
      expect(response).to redirect_to(band_path(band))
    end

    it "requires authentication" do
      band = create(:band)
      album = create(:album, :published, band: band)

      patch unpublish_band_album_path(band, album)

      expect(album.reload.status).to eq("published")
      expect(response).to redirect_to(new_user_session_path)
    end

    it "prevents a member of another band from unpublishing the album" do
      band = create(:band)
      album = create(:album, :published, band: band)
      outsider = create(:user)
      create(:band_membership, band: create(:band), user: outsider)
      sign_in outsider

      patch unpublish_band_album_path(band, album)

      expect(album.reload.status).to eq("published")
      expect(response).to redirect_to(root_path)
    end
  end

  describe "PATCH /bands/:band_id/albums/:id" do
    it "allows a band member to attach a cover" do
      user = create(:user)
      band = create(:band)
      create(:band_membership, band: band, user: user)
      album = create(:album, band: band)
      sign_in user

      cover = fixture_file_upload("band_photo.png", "image/png")

      patch band_album_path(band, album), params: { album: { cover: cover } }

      expect(response).to redirect_to(band_path(band))
      expect(album.reload.cover).to be_attached
    end

    it "rejects a non-image file and re-renders the form without erroring" do
      user = create(:user)
      band = create(:band)
      create(:band_membership, band: band, user: user)
      album = create(:album, band: band)
      sign_in user

      invalid_file = fixture_file_upload("invalid_photo.txt", "text/plain")

      patch band_album_path(band, album), params: { album: { cover: invalid_file } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(album.reload.cover).not_to be_attached
    end

    it "requires authentication" do
      band = create(:band)
      album = create(:album, band: band)

      patch band_album_path(band, album), params: { album: { cover: fixture_file_upload("band_photo.png", "image/png") } }

      expect(response).to redirect_to(new_user_session_path)
    end

    it "prevents a member of another band from editing the album" do
      band = create(:band)
      album = create(:album, band: band)
      outsider = create(:user)
      create(:band_membership, band: create(:band), user: outsider)
      sign_in outsider

      patch band_album_path(band, album), params: { album: { cover: fixture_file_upload("band_photo.png", "image/png") } }

      expect(response).to redirect_to(root_path)
      expect(album.reload.cover).not_to be_attached
    end
  end
end
