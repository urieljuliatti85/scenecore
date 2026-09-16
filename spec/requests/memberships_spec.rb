require "rails_helper"

RSpec.describe "Memberships", type: :request do
  describe "GET /bands/:band_id/supporters" do
    it "allows a band administrator to list the band's memberships" do
      band = create(:band)
      admin = create(:user)
      create(:band_membership, :administrator, band: band, user: admin)
      supporter = create(:membership, :supporter, band: band)
      sign_in admin

      get band_memberships_path(band)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(supporter.user.name)
    end

    it "allows a platform administrator to list any band's memberships" do
      band = create(:band)
      platform_admin = create(:user, :platform_admin)
      create(:membership, band: band)
      sign_in platform_admin

      get band_memberships_path(band)

      expect(response).to have_http_status(:ok)
    end

    it "does not allow a plain band member to list memberships" do
      band = create(:band)
      member = create(:user)
      create(:band_membership, band: band, user: member)
      sign_in member

      get band_memberships_path(band)

      expect(response).to redirect_to(root_path)
    end

    it "does not allow an administrator of a different band" do
      band = create(:band)
      admin = create(:user)
      create(:band_membership, :administrator, band: create(:band), user: admin)
      sign_in admin

      get band_memberships_path(band)

      expect(response).to redirect_to(root_path)
    end

    it "does not allow an unrelated user" do
      band = create(:band)
      outsider = create(:user)
      sign_in outsider

      get band_memberships_path(band)

      expect(response).to redirect_to(root_path)
    end

    it "does not leak another band's memberships" do
      band = create(:band)
      other_band = create(:band)
      admin = create(:user)
      create(:band_membership, :administrator, band: band, user: admin)
      other_bands_supporter = create(:membership, :supporter, band: other_band)
      sign_in admin

      get band_memberships_path(band)

      expect(response.body).not_to include(other_bands_supporter.user.name)
    end
  end

  describe "POST /bands/:band_id/supporters" do
    it "allows a band administrator to grant a membership to an existing user" do
      band = create(:band)
      admin = create(:user)
      create(:band_membership, :administrator, band: band, user: admin)
      fan = create(:user)
      sign_in admin

      expect {
        post band_memberships_path(band), params: { membership: { user_id: fan.id, level: "supporter" } }
      }.to change(Membership, :count).by(1)

      expect(band.memberships.find_by(user: fan).level).to eq("supporter")
    end

    it "does not allow a plain band member to grant a membership" do
      band = create(:band)
      member = create(:user)
      create(:band_membership, band: band, user: member)
      sign_in member

      expect {
        post band_memberships_path(band), params: { membership: { user_id: create(:user).id, level: "fan" } }
      }.not_to change(Membership, :count)
    end

    it "rejects granting a second membership to the same user for the same band" do
      band = create(:band)
      admin = create(:user)
      create(:band_membership, :administrator, band: band, user: admin)
      fan = create(:user)
      create(:membership, band: band, user: fan)
      sign_in admin

      expect {
        post band_memberships_path(band), params: { membership: { user_id: fan.id, level: "supporter" } }
      }.not_to change(Membership, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "PATCH /bands/:band_id/supporters/:id" do
    it "allows a band administrator to change a membership's level and status" do
      band = create(:band)
      admin = create(:user)
      create(:band_membership, :administrator, band: band, user: admin)
      membership = create(:membership, :fan, band: band)
      sign_in admin

      patch band_membership_path(band, membership), params: { membership: { level: "core_member", status: "paused" } }

      expect(membership.reload.level).to eq("core_member")
      expect(membership.status).to eq("paused")
    end

    it "does not allow a plain band member to change a membership" do
      band = create(:band)
      member = create(:user)
      create(:band_membership, band: band, user: member)
      membership = create(:membership, :fan, band: band)
      sign_in member

      patch band_membership_path(band, membership), params: { membership: { level: "core_member" } }

      expect(membership.reload.level).to eq("fan")
    end
  end

  describe "DELETE /bands/:band_id/supporters/:id" do
    it "allows a band administrator to remove a membership" do
      band = create(:band)
      admin = create(:user)
      create(:band_membership, :administrator, band: band, user: admin)
      membership = create(:membership, band: band)
      sign_in admin

      expect {
        delete band_membership_path(band, membership)
      }.to change(Membership, :count).by(-1)
    end

    it "does not allow a plain band member to remove a membership" do
      band = create(:band)
      member = create(:user)
      create(:band_membership, band: band, user: member)
      membership = create(:membership, band: band)
      sign_in member

      expect {
        delete band_membership_path(band, membership)
      }.not_to change(Membership, :count)
    end
  end

  describe "band isolation" do
    it "prevents an administrator of one band from managing another band's memberships" do
      band_a_admin = create(:user)
      band_a = create(:band)
      create(:band_membership, :administrator, band: band_a, user: band_a_admin)

      band_b = create(:band)
      band_b_membership = create(:membership, band: band_b)

      sign_in band_a_admin

      expect {
        post band_memberships_path(band_b), params: { membership: { user_id: create(:user).id, level: "fan" } }
      }.not_to change(Membership, :count)

      expect {
        delete band_membership_path(band_b, band_b_membership)
      }.not_to change(Membership, :count)
    end
  end

  describe "unauthenticated access" do
    it "redirects to sign in" do
      band = create(:band)

      get band_memberships_path(band)

      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
