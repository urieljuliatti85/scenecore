require "rails_helper"

RSpec.describe "Admin::Albums", type: :request do
  describe "GET /admin/albums" do
    it "lists published albums from any band for a platform admin" do
      admin = create(:user, :platform_admin)
      band = create(:band)
      published_album = create(:album, :published, band: band, title: "Loud Album")
      create(:album, band: band, title: "Quiet Draft")
      sign_in admin

      get admin_albums_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Loud Album")
      expect(response.body).not_to include("Quiet Draft")
    end

    it "returns 404 for a regular authenticated user" do
      user = create(:user)
      sign_in user

      get admin_albums_path

      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 for a band administrator who is not a platform admin" do
      user = create(:user)
      band = create(:band)
      create(:band_membership, :administrator, band: band, user: user)
      sign_in user

      get admin_albums_path

      expect(response).to have_http_status(:not_found)
    end

    it "requires authentication" do
      get admin_albums_path

      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "PATCH /admin/albums/:id/unpublish" do
    it "unpublishes an album regardless of which band owns it" do
      admin = create(:user, :platform_admin)
      band = create(:band)
      album = create(:album, :published, band: band)
      sign_in admin

      patch unpublish_admin_album_path(album)

      expect(album.reload.status).to eq("draft")
      expect(response).to redirect_to(admin_albums_path)
    end

    it "records an admin action log" do
      admin = create(:user, :platform_admin)
      band = create(:band)
      album = create(:album, :published, band: band)
      sign_in admin

      expect {
        patch unpublish_admin_album_path(album)
      }.to change(AdminActionLog, :count).by(1)

      log = AdminActionLog.last
      expect(log.actor).to eq(admin)
      expect(log.action).to eq("moderate_unpublish_album")
      expect(log.subject).to eq(album)
    end

    it "does not allow a regular user to unpublish an album" do
      user = create(:user)
      band = create(:band)
      album = create(:album, :published, band: band)
      sign_in user

      patch unpublish_admin_album_path(album)

      expect(album.reload.status).to eq("published")
      expect(response).to have_http_status(:not_found)
    end

    it "does not allow the album's own band administrator to use this route" do
      user = create(:user)
      band = create(:band)
      create(:band_membership, :administrator, band: band, user: user)
      album = create(:album, :published, band: band)
      sign_in user

      patch unpublish_admin_album_path(album)

      expect(album.reload.status).to eq("published")
      expect(response).to have_http_status(:not_found)
    end

    it "requires authentication" do
      band = create(:band)
      album = create(:album, :published, band: band)

      patch unpublish_admin_album_path(album)

      expect(response).to redirect_to(new_user_session_path)
      expect(album.reload.status).to eq("published")
    end
  end
end
