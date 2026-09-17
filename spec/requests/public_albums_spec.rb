require "rails_helper"

RSpec.describe "Public album pages", type: :request do
  describe "GET /:slug/albums/:id" do
    it "shows a published album without authentication" do
      band = create(:band, :approved)
      album = create(:album, :published, band: band, title: "Public Album")

      get public_album_path(band.slug, album)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Public Album")
    end

    it "shows the average rating and count when the album has ratings" do
      band = create(:band, :approved)
      album = create(:album, :published, band: band)
      create(:rating, album: album, score: 4)
      create(:rating, album: album, score: 2)

      get public_album_path(band.slug, album)

      expect(response.body).to include("3.0")
    end

    it "shows the Bandcamp embed player when the album has one" do
      band = create(:band, :approved)
      url = "https://bandcamp.com/EmbeddedPlayer/album=1234567890/size=large/"
      album = create(:album, :published, band: band, bandcamp_embed_url: url)

      get public_album_path(band.slug, album)

      expect(response.body).to include("<iframe")
      expect(response.body).to include(url)
    end

    it "does not show a Bandcamp player when the album has no embed URL" do
      band = create(:band, :approved)
      album = create(:album, :published, band: band)

      get public_album_path(band.slug, album)

      expect(response.body).not_to include("<iframe")
    end

    it "shows the Spotify player when the album has a Spotify id" do
      band = create(:band, :approved)
      album = create(:album, :published, band: band, spotify_id: "4aawyAB9vmqN3uQ7FjRGTy")

      get public_album_path(band.slug, album)

      expect(response.body).to include("https://open.spotify.com/embed/album/4aawyAB9vmqN3uQ7FjRGTy")
    end

    # spotify_link_id re-checks the stored value against the id format, so a
    # record written around the model can't put arbitrary text in an iframe src.
    it "does not embed a player for a malformed Spotify id" do
      band = create(:band, :approved)
      album = create(:album, :published, band: band)
      album.update_column(:spotify_id, "javascript:alert(1)")

      get public_album_path(band.slug, album)

      expect(response.body).not_to include("open.spotify.com/embed")
      expect(response.body).not_to include("javascript:alert(1)")
    end

    it "shows both players when the album has a Spotify id and a Bandcamp embed" do
      band = create(:band, :approved)
      album = create(:album, :published, band: band, spotify_id: "4aawyAB9vmqN3uQ7FjRGTy",
                                         bandcamp_embed_url: "https://bandcamp.com/EmbeddedPlayer/album=1234567890/size=large/")

      get public_album_path(band.slug, album)

      expect(response.body.scan("<iframe").size).to eq(2)
    end

    it "shows credited supporters" do
      band = create(:band, :approved)
      album = create(:album, :published, band: band)
      supporter = create(:user, name: "Alex Supporter")
      create(:membership, :supporter, band: band, user: supporter)
      create(:album_credit, album: album, user: supporter)

      get public_album_path(band.slug, album)

      expect(response.body).to include("Alex Supporter")
    end

    it "does not show a credits line when the album has no credits" do
      band = create(:band, :approved)
      album = create(:album, :published, band: band)

      get public_album_path(band.slug, album)

      expect(response.body).not_to include("Supported by")
    end

    it "returns 404 for a draft album" do
      band = create(:band, :approved)
      album = create(:album, band: band)

      get public_album_path(band.slug, album)

      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 for a band that is not approved" do
      band = create(:band)
      album = create(:album, :published, band: band)

      get public_album_path(band.slug, album)

      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 for an anonymous visitor during the album's early access window" do
      band = create(:band, :approved)
      album = create(:album, :published, band: band, early_access_level: :supporter, early_access_until: 1.day.from_now)

      get public_album_path(band.slug, album)

      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 for a signed-in user below the required early access level" do
      band = create(:band, :approved)
      album = create(:album, :published, band: band, early_access_level: :supporter, early_access_until: 1.day.from_now)
      fan = create(:user)
      create(:membership, band: band, user: fan, level: :fan)
      sign_in fan

      get public_album_path(band.slug, album)

      expect(response).to have_http_status(:not_found)
    end

    it "shows the album to a signed-in user who meets the required early access level" do
      band = create(:band, :approved)
      album = create(:album, :published, band: band, early_access_level: :supporter, early_access_until: 1.day.from_now, title: "Early Album")
      supporter = create(:user)
      create(:membership, band: band, user: supporter, level: :supporter)
      sign_in supporter

      get public_album_path(band.slug, album)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Early Album")
    end
  end

  describe "PUT /:slug/albums/:album_id/rating" do
    it "allows a signed-in user to rate a published album" do
      band = create(:band, :approved)
      album = create(:album, :published, band: band)
      user = create(:user)
      sign_in user

      expect {
        put album_rating_path(band.slug, album), params: { rating: { score: 4 } }
      }.to change(Rating, :count).by(1)

      expect(album.ratings.find_by(user: user).score).to eq(4)
    end

    it "allows updating an existing rating instead of creating a second one" do
      band = create(:band, :approved)
      album = create(:album, :published, band: band)
      user = create(:user)
      create(:rating, album: album, user: user, score: 2)
      sign_in user

      expect {
        put album_rating_path(band.slug, album), params: { rating: { score: 5 } }
      }.not_to change(Rating, :count)

      expect(album.ratings.find_by(user: user).score).to eq(5)
    end

    it "rejects an out-of-range score" do
      band = create(:band, :approved)
      album = create(:album, :published, band: band)
      user = create(:user)
      sign_in user

      expect {
        put album_rating_path(band.slug, album), params: { rating: { score: 9 } }
      }.not_to change(Rating, :count)
    end

    it "requires authentication" do
      band = create(:band, :approved)
      album = create(:album, :published, band: band)

      put album_rating_path(band.slug, album), params: { rating: { score: 4 } }

      expect(response).to redirect_to(new_user_session_path)
    end

    it "does not allow rating a draft album" do
      band = create(:band, :approved)
      album = create(:album, band: band)
      user = create(:user)
      sign_in user

      put album_rating_path(band.slug, album), params: { rating: { score: 4 } }

      expect(response).to have_http_status(:not_found)
    end
  end
end
