require "rails_helper"

RSpec.describe "Follows", type: :request do
  describe "POST /bands/:band_id/follow" do
    it "creates a follow for an authenticated user" do
      user = create(:user)
      band = create(:band, :approved)
      sign_in user

      expect {
        post band_follow_path(band)
      }.to change(Follow, :count).by(1)

      expect(Follow.last.user).to eq(user)
      expect(Follow.last.band).to eq(band)
      expect(response).to redirect_to(public_band_path(band.slug))
    end

    it "does not create a duplicate follow when the user already follows the band" do
      user = create(:user)
      band = create(:band, :approved)
      create(:follow, user: user, band: band)
      sign_in user

      expect {
        post band_follow_path(band)
      }.not_to change(Follow, :count)
    end

    it "requires authentication" do
      band = create(:band, :approved)

      expect {
        post band_follow_path(band)
      }.not_to change(Follow, :count)

      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "DELETE /bands/:band_id/follow" do
    it "removes the user's follow" do
      user = create(:user)
      band = create(:band, :approved)
      create(:follow, user: user, band: band)
      sign_in user

      expect {
        delete band_follow_path(band)
      }.to change(Follow, :count).by(-1)

      expect(response).to redirect_to(public_band_path(band.slug))
    end

    it "does not remove another user's follow" do
      owner = create(:user)
      band = create(:band, :approved)
      create(:follow, user: owner, band: band)
      other_user = create(:user)
      sign_in other_user

      expect {
        delete band_follow_path(band)
      }.not_to change(Follow, :count)
    end

    it "is a no-op when the user does not follow the band" do
      user = create(:user)
      band = create(:band, :approved)
      sign_in user

      expect {
        delete band_follow_path(band)
      }.not_to change(Follow, :count)
    end

    it "requires authentication" do
      band = create(:band, :approved)

      delete band_follow_path(band)

      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
