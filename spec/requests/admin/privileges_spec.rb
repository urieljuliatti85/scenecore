require "rails_helper"

RSpec.describe "Admin::Privileges", type: :request do
  describe "GET /admin/bands/:band_id/privileges" do
    it "lists the band's members for a platform admin" do
      admin = create(:user, :platform_admin)
      band = create(:band)
      member = create(:user, name: "Band Owner")
      create(:band_membership, :administrator, band: band, user: member)
      sign_in admin

      get admin_band_privileges_path(band)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Band Owner")
    end

    it "returns 404 for a regular authenticated user" do
      user = create(:user)
      band = create(:band)
      sign_in user

      get admin_band_privileges_path(band)

      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 for the band's own administrator" do
      user = create(:user)
      band = create(:band)
      create(:band_membership, :administrator, band: band, user: user)
      sign_in user

      get admin_band_privileges_path(band)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /admin/bands/:band_id/privileges" do
    it "grants administrator privileges to a user with no membership" do
      admin = create(:user, :platform_admin)
      band = create(:band)
      target = create(:user)
      sign_in admin

      expect {
        post admin_band_privileges_path(band), params: { user_id: target.id }
      }.to change(BandMembership, :count).by(1)

      expect(band.band_memberships.find_by(user: target).role).to eq("administrator")
      expect(response).to redirect_to(admin_band_privileges_path(band))
    end

    it "promotes an existing plain member to administrator" do
      admin = create(:user, :platform_admin)
      band = create(:band)
      target = create(:user)
      create(:band_membership, band: band, user: target)
      sign_in admin

      expect {
        post admin_band_privileges_path(band), params: { user_id: target.id }
      }.not_to change(BandMembership, :count)

      expect(band.band_memberships.find_by(user: target).role).to eq("administrator")
    end

    it "does not allow a regular user to grant privileges" do
      user = create(:user)
      band = create(:band)
      target = create(:user)
      sign_in user

      expect {
        post admin_band_privileges_path(band), params: { user_id: target.id }
      }.not_to change(BandMembership, :count)

      expect(response).to have_http_status(:not_found)
    end

    it "requires authentication" do
      band = create(:band)
      target = create(:user)

      expect {
        post admin_band_privileges_path(band), params: { user_id: target.id }
      }.not_to change(BandMembership, :count)

      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "PATCH /admin/bands/:band_id/privileges/:id" do
    it "demotes an administrator to member when another administrator remains" do
      admin = create(:user, :platform_admin)
      band = create(:band)
      create(:band_membership, :administrator, band: band)
      target_membership = create(:band_membership, :administrator, band: band)
      sign_in admin

      patch admin_band_privilege_path(band, target_membership), params: { role: "member" }

      expect(target_membership.reload.role).to eq("member")
    end

    it "does not allow demoting the last administrator" do
      admin = create(:user, :platform_admin)
      band = create(:band)
      only_admin_membership = create(:band_membership, :administrator, band: band)
      sign_in admin

      patch admin_band_privilege_path(band, only_admin_membership), params: { role: "member" }

      expect(only_admin_membership.reload.role).to eq("administrator")
      expect(response).to redirect_to(admin_band_privileges_path(band))
    end

    it "does not allow a regular user to change roles" do
      user = create(:user)
      band = create(:band)
      membership = create(:band_membership, :administrator, band: band)
      sign_in user

      patch admin_band_privilege_path(band, membership), params: { role: "member" }

      expect(response).to have_http_status(:not_found)
    end

    it "requires authentication" do
      band = create(:band)
      membership = create(:band_membership, :administrator, band: band)

      patch admin_band_privilege_path(band, membership), params: { role: "member" }

      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
