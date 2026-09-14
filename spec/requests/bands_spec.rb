require "rails_helper"

RSpec.describe "Bands", type: :request do
  describe "GET /bands/new" do
    it "redirects to sign in when unauthenticated" do
      get new_band_path

      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "POST /bands" do
    it "requires authentication" do
      post bands_path, params: { band: { name: "The Testers" } }

      expect(response).to redirect_to(new_user_session_path)
    end

    it "creates a pending band and makes the creator its administrator" do
      user = create(:user)
      sign_in user

      expect {
        post bands_path, params: { band: { name: "The Testers" } }
      }.to change(Band, :count).by(1)

      band = Band.last
      expect(band.status).to eq("pending")
      expect(band.band_memberships.find_by(user: user).role).to eq("administrator")
      expect(response).to redirect_to(band_path(band))
    end

    it "does not create a band or membership when validation fails" do
      user = create(:user)
      sign_in user

      expect {
        post bands_path, params: { band: { name: "" } }
      }.to change(Band, :count).by(0).and(change(BandMembership, :count).by(0))

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "GET /bands/:id" do
    it "allows a band administrator to view their band" do
      user = create(:user)
      band = create(:band)
      create(:band_membership, :administrator, band: band, user: user)
      sign_in user

      get band_path(band)

      expect(response).to have_http_status(:ok)
    end

    it "allows a band member to view their band" do
      user = create(:user)
      band = create(:band)
      create(:band_membership, band: band, user: user)
      sign_in user

      get band_path(band)

      expect(response).to have_http_status(:ok)
    end

    it "returns 404 for a non-member, not 403, to avoid leaking existence" do
      user = create(:user)
      band = create(:band)
      sign_in user

      get band_path(band)

      expect(response).to have_http_status(:not_found)
    end

    it "allows a platform admin to view any band" do
      user = create(:user, :platform_admin)
      band = create(:band)
      sign_in user

      get band_path(band)

      expect(response).to have_http_status(:ok)
    end
  end

  describe "band isolation" do
    it "prevents an administrator of one band from editing another band, even by crafting the URL" do
      band_a_admin = create(:user)
      band_a = create(:band)
      create(:band_membership, :administrator, band: band_a, user: band_a_admin)

      band_b = create(:band, name: "Band B")

      sign_in band_a_admin

      get edit_band_path(band_b)
      expect(response).to have_http_status(:not_found)

      patch band_path(band_b), params: { band: { name: "Hijacked" } }
      expect(response).to have_http_status(:not_found)
      expect(band_b.reload.name).to eq("Band B")
    end

    it "prevents a band administrator from approving or rejecting their own band" do
      user = create(:user)
      band = create(:band)
      create(:band_membership, :administrator, band: band, user: user)
      sign_in user

      patch approve_band_path(band)

      expect(band.reload.status).to eq("pending")
    end
  end

  describe "PATCH /bands/:id (photo upload)" do
    it "attaches a valid photo" do
      user = create(:user)
      band = create(:band)
      create(:band_membership, :administrator, band: band, user: user)
      sign_in user

      photo = fixture_file_upload("band_photo.png", "image/png")

      patch band_path(band), params: { band: { photo: photo } }

      expect(response).to redirect_to(band_path(band))
      expect(band.reload.photo).to be_attached
    end

    it "rejects a non-image file and re-renders the form without erroring" do
      user = create(:user)
      band = create(:band)
      create(:band_membership, :administrator, band: band, user: user)
      sign_in user

      invalid_file = fixture_file_upload("invalid_photo.txt", "text/plain")

      patch band_path(band), params: { band: { photo: invalid_file } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("must be a PNG, JPEG, or WebP image")
      expect(band.reload.photo).not_to be_attached
    end
  end

  describe "PATCH /bands/:id/approve" do
    it "allows a platform admin to approve a band" do
      admin = create(:user, :platform_admin)
      band = create(:band)
      sign_in admin

      patch approve_band_path(band)

      expect(band.reload.status).to eq("approved")
    end

    it "does not allow a regular user to approve a band" do
      user = create(:user)
      band = create(:band)
      sign_in user

      patch approve_band_path(band)

      expect(band.reload.status).to eq("pending")
    end

    it "requires authentication" do
      band = create(:band)

      patch approve_band_path(band)

      expect(response).to redirect_to(new_user_session_path)
      expect(band.reload.status).to eq("pending")
    end
  end
end
