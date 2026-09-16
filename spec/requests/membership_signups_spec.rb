require "rails_helper"

RSpec.describe "Membership signups", type: :request do
  describe "POST /bands/:band_id/membership_signup" do
    it "lets a signed-in user join an approved band at the chosen level" do
      band = create(:band, :approved)
      user = create(:user)
      sign_in user

      post band_membership_signup_path(band), params: { membership: { level: "supporter" } }

      membership = Membership.find_by(band: band, user: user)
      expect(membership).to be_present
      expect(membership.level).to eq("supporter")
      expect(membership.status).to eq("active")
      expect(response).to redirect_to(public_band_path(band.slug))
    end

    it "lets an existing member change their level" do
      band = create(:band, :approved)
      user = create(:user)
      membership = create(:membership, :fan, band: band, user: user)
      sign_in user

      post band_membership_signup_path(band), params: { membership: { level: "core_member" } }

      expect(membership.reload.level).to eq("core_member")
    end

    it "does not create a second membership for the same user and band" do
      band = create(:band, :approved)
      user = create(:user)
      create(:membership, :fan, band: band, user: user)
      sign_in user

      expect {
        post band_membership_signup_path(band), params: { membership: { level: "supporter" } }
      }.not_to change(Membership, :count)
    end

    it "rejects an invalid level" do
      band = create(:band, :approved)
      user = create(:user)
      sign_in user

      post band_membership_signup_path(band), params: { membership: { level: "vip" } }

      expect(Membership.find_by(band: band, user: user)).to be_nil
    end

    it "does not allow joining a band that is not approved" do
      band = create(:band)
      user = create(:user)
      sign_in user

      post band_membership_signup_path(band), params: { membership: { level: "fan" } }

      expect(response).to have_http_status(:not_found)
      expect(Membership.find_by(band: band, user: user)).to be_nil
    end

    it "requires authentication" do
      band = create(:band, :approved)

      post band_membership_signup_path(band), params: { membership: { level: "fan" } }

      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "DELETE /bands/:band_id/membership_signup" do
    it "lets a signed-in user cancel their own membership" do
      band = create(:band, :approved)
      user = create(:user)
      membership = create(:membership, :supporter, band: band, user: user, status: :active)
      sign_in user

      delete band_membership_signup_path(band)

      expect(membership.reload.status).to eq("cancelled")
      expect(response).to redirect_to(public_band_path(band.slug))
    end

    it "requires authentication" do
      band = create(:band, :approved)
      membership = create(:membership, band: band)

      delete band_membership_signup_path(band)

      expect(response).to redirect_to(new_user_session_path)
      expect(membership.reload.status).to eq("active")
    end

    it "returns 404 when the user has no membership with the band" do
      band = create(:band, :approved)
      user = create(:user)
      sign_in user

      delete band_membership_signup_path(band)

      expect(response).to have_http_status(:not_found)
    end
  end
end
