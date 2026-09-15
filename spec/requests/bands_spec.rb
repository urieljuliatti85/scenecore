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

    it "does not run one track query per album" do
      user = create(:user)
      band = create(:band)
      create(:band_membership, band: band, user: user)
      3.times do |i|
        album = create(:album, band: band)
        create(:track, album: album, track_number: i + 1)
      end
      sign_in user

      track_queries = 0
      subscriber = ActiveSupport::Notifications.subscribe("sql.active_record") do |*, payload|
        track_queries += 1 if payload[:sql].include?('"tracks"') && payload[:name] != "SCHEMA"
      end
      get band_path(band)
      ActiveSupport::Notifications.unsubscribe(subscriber)

      expect(track_queries).to eq(1)
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

  describe "PATCH /bands/:id (social links)" do
    it "updates the band's social links" do
      user = create(:user)
      band = create(:band)
      create(:band_membership, :administrator, band: band, user: user)
      sign_in user

      patch band_path(band), params: { band: { spotify_url: "https://open.spotify.com/artist/1" } }

      expect(response).to redirect_to(band_path(band))
      expect(band.reload.spotify_url).to eq("https://open.spotify.com/artist/1")
    end

    it "rejects an invalid social link URL" do
      user = create(:user)
      band = create(:band)
      create(:band_membership, :administrator, band: band, user: user)
      sign_in user

      patch band_path(band), params: { band: { spotify_url: "not a url" } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("must be a valid URL")
    end
  end

  describe "PATCH /bands/:id (category)" do
    it "allows the band's administrator to set the band's category" do
      user = create(:user)
      band = create(:band)
      create(:band_membership, :administrator, band: band, user: user)
      category = create(:category, name: "Rock")
      sign_in user

      patch band_path(band), params: { band: { category_id: category.id } }

      expect(band.reload.category).to eq(category)
    end

    it "allows clearing the band's category" do
      user = create(:user)
      category = create(:category)
      band = create(:band, category: category)
      create(:band_membership, :administrator, band: band, user: user)
      sign_in user

      patch band_path(band), params: { band: { category_id: "" } }

      expect(band.reload.category).to be_nil
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

    it "records an admin action log" do
      admin = create(:user, :platform_admin)
      band = create(:band)
      sign_in admin

      expect {
        patch approve_band_path(band)
      }.to change(AdminActionLog, :count).by(1)

      log = AdminActionLog.last
      expect(log.actor).to eq(admin)
      expect(log.action).to eq("approve_band")
      expect(log.subject).to eq(band)
    end
  end

  describe "PATCH /bands/:id/reject" do
    it "records an admin action log" do
      admin = create(:user, :platform_admin)
      band = create(:band)
      sign_in admin

      expect {
        patch reject_band_path(band)
      }.to change(AdminActionLog, :count).by(1)

      expect(AdminActionLog.last.action).to eq("reject_band")
    end
  end

  describe "PATCH /bands/:id/suspend" do
    it "allows a platform admin to suspend an approved band" do
      admin = create(:user, :platform_admin)
      band = create(:band, :approved)
      sign_in admin

      patch suspend_band_path(band)

      expect(band.reload.status).to eq("suspended")
    end

    it "records an admin action log" do
      admin = create(:user, :platform_admin)
      band = create(:band, :approved)
      sign_in admin

      expect {
        patch suspend_band_path(band)
      }.to change(AdminActionLog, :count).by(1)

      expect(AdminActionLog.last.action).to eq("suspend_band")
    end

    it "does not allow a regular user to suspend a band" do
      user = create(:user)
      band = create(:band, :approved)
      sign_in user

      patch suspend_band_path(band)

      expect(band.reload.status).to eq("approved")
    end

    it "does not allow the band's own administrator to suspend it" do
      user = create(:user)
      band = create(:band, :approved)
      create(:band_membership, :administrator, band: band, user: user)
      sign_in user

      patch suspend_band_path(band)

      expect(band.reload.status).to eq("approved")
    end

    it "requires authentication" do
      band = create(:band, :approved)

      patch suspend_band_path(band)

      expect(response).to redirect_to(new_user_session_path)
      expect(band.reload.status).to eq("approved")
    end

    it "makes the band's public page inaccessible" do
      admin = create(:user, :platform_admin)
      band = create(:band, :approved)
      sign_in admin

      patch suspend_band_path(band)

      get public_band_path(band.slug)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PATCH /bands/:id/reactivate" do
    it "allows a platform admin to reactivate a suspended band" do
      admin = create(:user, :platform_admin)
      band = create(:band, :suspended)
      sign_in admin

      patch reactivate_band_path(band)

      expect(band.reload.status).to eq("approved")
    end

    it "records an admin action log" do
      admin = create(:user, :platform_admin)
      band = create(:band, :suspended)
      sign_in admin

      expect {
        patch reactivate_band_path(band)
      }.to change(AdminActionLog, :count).by(1)

      expect(AdminActionLog.last.action).to eq("reactivate_band")
    end

    it "does not allow a regular user to reactivate a band" do
      user = create(:user)
      band = create(:band, :suspended)
      sign_in user

      patch reactivate_band_path(band)

      expect(band.reload.status).to eq("suspended")
    end

    it "requires authentication" do
      band = create(:band, :suspended)

      patch reactivate_band_path(band)

      expect(response).to redirect_to(new_user_session_path)
      expect(band.reload.status).to eq("suspended")
    end
  end
end
