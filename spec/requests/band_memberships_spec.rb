require "rails_helper"

RSpec.describe "BandMemberships", type: :request do
  describe "POST /bands/:band_id/members" do
    it "allows a band administrator to add an existing user as a member" do
      band = create(:band)
      admin = create(:user)
      create(:band_membership, :administrator, band: band, user: admin)
      new_member = create(:user)
      sign_in admin

      expect {
        post band_band_memberships_path(band), params: { band_membership: { user_id: new_member.id, role: "member" } }
      }.to change(BandMembership, :count).by(1)

      expect(band.reload.members).to include(new_member)
    end

    it "does not allow a plain member to add other members" do
      band = create(:band)
      member = create(:user)
      create(:band_membership, band: band, user: member)
      other_user = create(:user)
      sign_in member

      expect {
        post band_band_memberships_path(band), params: { band_membership: { user_id: other_user.id, role: "member" } }
      }.not_to change(BandMembership, :count)
    end

    it "does not allow a non-member to add members" do
      band = create(:band)
      outsider = create(:user)
      other_user = create(:user)
      sign_in outsider

      expect {
        post band_band_memberships_path(band), params: { band_membership: { user_id: other_user.id, role: "member" } }
      }.not_to change(BandMembership, :count)
    end

    it "rejects adding the same user to a band twice" do
      band = create(:band)
      admin = create(:user)
      create(:band_membership, :administrator, band: band, user: admin)
      existing_member = create(:user)
      create(:band_membership, band: band, user: existing_member)
      sign_in admin

      expect {
        post band_band_memberships_path(band), params: { band_membership: { user_id: existing_member.id, role: "member" } }
      }.not_to change(BandMembership, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "DELETE /bands/:band_id/members/:id" do
    it "allows a band administrator to remove a member" do
      band = create(:band)
      admin = create(:user)
      create(:band_membership, :administrator, band: band, user: admin)
      member = create(:user)
      membership = create(:band_membership, band: band, user: member)
      sign_in admin

      expect {
        delete band_band_membership_path(band, membership)
      }.to change(BandMembership, :count).by(-1)
    end

    it "does not allow a plain member to remove another member" do
      band = create(:band)
      member = create(:user)
      create(:band_membership, band: band, user: member)
      other_membership = create(:band_membership, band: band, user: create(:user))
      sign_in member

      expect {
        delete band_band_membership_path(band, other_membership)
      }.not_to change(BandMembership, :count)
    end
  end

  describe "band isolation" do
    it "prevents an administrator of one band from managing members of another band" do
      band_a_admin = create(:user)
      band_a = create(:band)
      create(:band_membership, :administrator, band: band_a, user: band_a_admin)

      band_b = create(:band)
      band_b_member = create(:user)
      band_b_membership = create(:band_membership, band: band_b, user: band_b_member)

      sign_in band_a_admin

      expect {
        post band_band_memberships_path(band_b), params: { band_membership: { user_id: create(:user).id, role: "member" } }
      }.not_to change(BandMembership, :count)

      expect {
        delete band_band_membership_path(band_b, band_b_membership)
      }.not_to change(BandMembership, :count)
    end
  end

  describe "unauthenticated access" do
    it "redirects to sign in" do
      band = create(:band)

      get band_band_memberships_path(band)

      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
