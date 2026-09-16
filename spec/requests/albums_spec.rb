require "rails_helper"

RSpec.describe "Albums", type: :request do
  describe "PATCH /bands/:band_id/albums/:id/refetch_cover" do
    def member_and_album(spotify_id: "4uLU6hMCjMI75M1A2tKUQC")
      user = create(:user)
      band = create(:band)
      create(:band_membership, band: band, user: user)
      album = create(:album, band: band, spotify_id: spotify_id)
      [ user, band, album ]
    end

    it "updates the cover from Spotify" do
      user, band, album = member_and_album
      details = SpotifyClient::AlbumDetails.new(name: album.title, cover_image_url: "https://i.scdn.co/image/new.jpg")
      allow_any_instance_of(SpotifyClient).to receive(:fetch_album).with(album.spotify_id).and_return(details)
      sign_in user

      patch refetch_cover_band_album_path(band, album)

      expect(album.reload.spotify_cover_url).to eq("https://i.scdn.co/image/new.jpg")
      expect(response).to redirect_to(band_album_path(band, album))
    end

    it "tells the band when the album did not come from Spotify" do
      user, band, album = member_and_album(spotify_id: nil)
      sign_in user

      patch refetch_cover_band_album_path(band, album)

      expect(flash[:alert]).to match(/not imported from Spotify/)
    end

    it "does not fail when Spotify is unavailable" do
      user, band, album = member_and_album
      allow_any_instance_of(SpotifyClient).to receive(:fetch_album).and_raise(SpotifyClient::Error)
      sign_in user

      patch refetch_cover_band_album_path(band, album)

      expect(flash[:alert]).to match(/Could not reach Spotify/)
    end

    it "prevents a member of another band from refetching" do
      outsider = create(:user)
      create(:band_membership, band: create(:band), user: outsider)
      album = create(:album, spotify_id: "4uLU6hMCjMI75M1A2tKUQC")
      sign_in outsider

      patch refetch_cover_band_album_path(album.band, album)

      expect(response).to redirect_to(root_path)
    end

    it "requires authentication" do
      album = create(:album)

      patch refetch_cover_band_album_path(album.band, album)

      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "PATCH /bands/:band_id/albums/:id/cover_from_url" do
    it "attaches an image fetched from the given URL" do
      user = create(:user)
      band = create(:band)
      create(:band_membership, band: band, user: user)
      album = create(:album, band: band)
      png = Rails.root.join("spec/fixtures/files/band_photo.png").binread
      allow_any_instance_of(RemoteImageFetcher).to receive(:call).with("https://example.com/cover.png")
        .and_return(RemoteImageFetcher::Result.new(io: StringIO.new(png), filename: "cover.png", content_type: "image/png"))
      sign_in user

      patch cover_from_url_band_album_path(band, album), params: { cover_url: "https://example.com/cover.png" }

      expect(album.reload.cover).to be_attached
      expect(flash[:notice]).to eq("Cover updated.")
    end

    it "shows the fetcher's message when the URL is rejected" do
      user = create(:user)
      band = create(:band)
      create(:band_membership, band: band, user: user)
      album = create(:album, band: band)
      allow_any_instance_of(RemoteImageFetcher).to receive(:call)
        .and_raise(RemoteImageFetcher::Error, "That URL is not publicly reachable.")
      sign_in user

      patch cover_from_url_band_album_path(band, album), params: { cover_url: "http://169.254.169.254/" }

      expect(album.reload.cover).not_to be_attached
      expect(flash[:alert]).to eq("That URL is not publicly reachable.")
    end

    it "prevents a member of another band from setting a cover" do
      outsider = create(:user)
      create(:band_membership, band: create(:band), user: outsider)
      album = create(:album)
      sign_in outsider

      patch cover_from_url_band_album_path(album.band, album), params: { cover_url: "https://example.com/cover.png" }

      expect(response).to redirect_to(root_path)
    end
  end

  describe "GET /bands/:band_id/albums/:id" do
    it "requires authentication" do
      album = create(:album)

      get band_album_path(album.band, album)

      expect(response).to redirect_to(new_user_session_path)
    end

    it "shows the album and its Spotify link to a band member" do
      user = create(:user)
      band = create(:band)
      create(:band_membership, band: band, user: user)
      album = create(:album, band: band, title: "Demon's Massacre", spotify_id: "4uLU6hMCjMI75M1A2tKUQC")
      sign_in user

      get band_album_path(band, album)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Demon&#39;s Massacre")
      expect(response.body).to include("Listen on Spotify")
      expect(response.body).to include("https://open.spotify.com/album/4uLU6hMCjMI75M1A2tKUQC")
    end

    it "prevents a member of another band from viewing the album" do
      outsider = create(:user)
      create(:band_membership, band: create(:band), user: outsider)
      album = create(:album)
      sign_in outsider

      get band_album_path(album.band, album)

      expect(response).to redirect_to(root_path)
    end

    it "does not expose an album belonging to a different band" do
      user = create(:user)
      band = create(:band)
      create(:band_membership, band: band, user: user)
      other_album = create(:album)
      sign_in user

      get band_album_path(band, other_album)

      expect(response).to have_http_status(:not_found)
    end
  end

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

    it "reports Spotify as unavailable, rather than failing, when the network drops" do
      user = create(:user)
      band = create(:band)
      create(:band_membership, band: band, user: user)
      sign_in user
      # Stubbed at the client rather than Net::HTTP so the test doesn't
      # depend on Spotify credentials being decryptable (CI has no master key).
      allow_any_instance_of(SpotifyClient).to receive(:search_albums)
        .and_raise(SpotifyClient::Error, "Spotify request failed: Errno::ECONNREFUSED")

      get search_band_albums_path(band), params: { q: "Discovery" }

      expect(response).to have_http_status(:bad_gateway)
      expect(JSON.parse(response.body)["error"]).to match(/unavailable/i)
    end
  end

  describe "POST /bands/:band_id/albums" do
    let(:fetched_album) do
      SpotifyClient::AlbumDetails.new(
        name: "Discovery",
        cover_image_url: "https://i.scdn.co/image/discovery-cover.jpg"
      )
    end

    it "imports the album for a band member" do
      user = create(:user)
      band = create(:band)
      create(:band_membership, band: band, user: user)
      sign_in user
      allow_any_instance_of(SpotifyClient).to receive(:fetch_album).with("4uLU6hMCjMI75M1A2tKUQC").and_return(fetched_album)

      expect {
        post band_albums_path(band), params: { spotify_album_id: "4uLU6hMCjMI75M1A2tKUQC" }
      }.to change(Album, :count).by(1)

      album = Album.last
      expect(album.title).to eq("Discovery")
      expect(album.band).to eq(band)
      expect(album.spotify_id).to eq("4uLU6hMCjMI75M1A2tKUQC")
      expect(album.spotify_cover_url).to eq("https://i.scdn.co/image/discovery-cover.jpg")
      expect(response).to redirect_to(band_path(band))
    end

    # The old import mirrored Spotify's track listing into the database.
    it "does not create tracks" do
      user = create(:user)
      band = create(:band)
      create(:band_membership, band: band, user: user)
      sign_in user
      allow_any_instance_of(SpotifyClient).to receive(:fetch_album).and_return(fetched_album)

      expect {
        post band_albums_path(band), params: { spotify_album_id: "4uLU6hMCjMI75M1A2tKUQC" }
      }.not_to change(Track, :count)
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
    it "publishes the album" do
      user = create(:user)
      band = create(:band)
      create(:band_membership, band: band, user: user)
      album = create(:album, band: band)
      sign_in user

      patch publish_band_album_path(band, album)

      expect(album.reload.status).to eq("published")
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
    it "reverts the album to draft" do
      user = create(:user)
      band = create(:band)
      create(:band_membership, band: band, user: user)
      album = create(:album, :published, band: band)
      sign_in user

      patch unpublish_band_album_path(band, album)

      expect(album.reload.status).to eq("draft")
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

  describe "PATCH /bands/:band_id/albums/:id with a Spotify album id" do
    let(:details) do
      SpotifyClient::AlbumDetails.new(name: "Discovery", cover_image_url: "https://i.scdn.co/image/new.jpg")
    end

    def member_for(band)
      user = create(:user)
      create(:band_membership, band: band, user: user)
      user
    end

    # The reason this exists: albums added before spotify_id was a column
    # have no link, and re-importing meant deleting the album.
    it "links an album that has no Spotify id yet" do
      band = create(:band)
      album = create(:album, band: band, spotify_id: nil, title: "Kept Title")
      sign_in member_for(band)
      allow_any_instance_of(SpotifyClient).to receive(:fetch_album).with("4aawyAB9vmqN3uQ7FjRGTy").and_return(details)

      patch band_album_path(band, album), params: { spotify_album_id: "4aawyAB9vmqN3uQ7FjRGTy" }

      album.reload
      expect(album.spotify_id).to eq("4aawyAB9vmqN3uQ7FjRGTy")
      expect(album.spotify_cover_url).to eq("https://i.scdn.co/image/new.jpg")
      expect(response).to redirect_to(band_album_path(band, album))
    end

    # The band may have corrected the title; linking must not undo that.
    it "does not overwrite the album title" do
      band = create(:band)
      album = create(:album, band: band, spotify_id: nil, title: "Kept Title")
      sign_in member_for(band)
      allow_any_instance_of(SpotifyClient).to receive(:fetch_album).and_return(details)

      patch band_album_path(band, album), params: { spotify_album_id: "4aawyAB9vmqN3uQ7FjRGTy" }

      expect(album.reload.title).to eq("Kept Title")
    end

    it "rejects an id that is not a Spotify album id" do
      band = create(:band)
      album = create(:album, band: band, spotify_id: nil)
      sign_in member_for(band)

      patch band_album_path(band, album), params: { spotify_album_id: "javascript:alert(1)" }

      expect(album.reload.spotify_id).to be_nil
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "tells the band when Spotify cannot be reached" do
      band = create(:band)
      album = create(:album, band: band, spotify_id: nil)
      sign_in member_for(band)
      allow_any_instance_of(SpotifyClient).to receive(:fetch_album).and_raise(SpotifyClient::Error)

      patch band_album_path(band, album), params: { spotify_album_id: "4aawyAB9vmqN3uQ7FjRGTy" }

      expect(album.reload.spotify_id).to be_nil
      expect(response).to have_http_status(:bad_gateway)
    end

    it "prevents a member of another band from linking the album" do
      band = create(:band)
      album = create(:album, band: band, spotify_id: nil)
      outsider = create(:user)
      create(:band_membership, band: create(:band), user: outsider)
      sign_in outsider

      patch band_album_path(band, album), params: { spotify_album_id: "4aawyAB9vmqN3uQ7FjRGTy" }

      expect(album.reload.spotify_id).to be_nil
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
