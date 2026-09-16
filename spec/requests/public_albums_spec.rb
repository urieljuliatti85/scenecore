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
