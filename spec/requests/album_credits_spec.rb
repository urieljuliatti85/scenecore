require "rails_helper"

RSpec.describe "Album Credits", type: :request do
  describe "POST /bands/:band_id/albums/:album_id/credits" do
    it "credits a Supporter by email for a band member" do
      band = create(:band)
      album = create(:album, band: band)
      band_member = create(:user)
      create(:band_membership, band: band, user: band_member)
      supporter = create(:user, email: "supporter@example.com")
      create(:membership, :supporter, band: band, user: supporter)
      sign_in band_member

      expect {
        post band_album_credits_path(band, album), params: { email: "supporter@example.com" }
      }.to change(AlbumCredit, :count).by(1)

      expect(AlbumCredit.last.user).to eq(supporter)
      expect(response).to redirect_to(edit_band_album_path(band, album))
    end

    it "rejects crediting a user with only a Fan membership" do
      band = create(:band)
      album = create(:album, band: band)
      band_member = create(:user)
      create(:band_membership, band: band, user: band_member)
      fan = create(:user, email: "fan@example.com")
      create(:membership, band: band, user: fan, level: :fan)
      sign_in band_member

      expect {
        post band_album_credits_path(band, album), params: { email: "fan@example.com" }
      }.not_to change(AlbumCredit, :count)
    end

    it "shows an error when no user matches the email" do
      band = create(:band)
      album = create(:album, band: band)
      band_member = create(:user)
      create(:band_membership, band: band, user: band_member)
      sign_in band_member

      post band_album_credits_path(band, album), params: { email: "nobody@example.com" }

      expect(response).to redirect_to(edit_band_album_path(band, album))
      follow_redirect!
      expect(response.body).to include("No user found")
    end

    it "prevents a member of another band from crediting this album" do
      band = create(:band)
      album = create(:album, band: band)
      supporter = create(:user, email: "supporter@example.com")
      create(:membership, :supporter, band: band, user: supporter)
      outsider = create(:user)
      create(:band_membership, band: create(:band), user: outsider)
      sign_in outsider

      expect {
        post band_album_credits_path(band, album), params: { email: "supporter@example.com" }
      }.not_to change(AlbumCredit, :count)

      expect(response).to redirect_to(root_path)
    end

    it "requires authentication" do
      band = create(:band)
      album = create(:album, band: band)

      post band_album_credits_path(band, album), params: { email: "supporter@example.com" }

      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "DELETE /bands/:band_id/albums/:album_id/credits/:id" do
    it "removes a credit for a band member" do
      band = create(:band)
      album = create(:album, band: band)
      band_member = create(:user)
      create(:band_membership, band: band, user: band_member)
      supporter = create(:user)
      create(:membership, :supporter, band: band, user: supporter)
      credit = create(:album_credit, album: album, user: supporter)
      sign_in band_member

      expect {
        delete band_album_credit_path(band, album, credit)
      }.to change(AlbumCredit, :count).by(-1)
    end

    it "prevents a member of another band from removing the credit" do
      band = create(:band)
      album = create(:album, band: band)
      supporter = create(:user)
      create(:membership, :supporter, band: band, user: supporter)
      credit = create(:album_credit, album: album, user: supporter)
      outsider = create(:user)
      create(:band_membership, band: create(:band), user: outsider)
      sign_in outsider

      expect {
        delete band_album_credit_path(band, album, credit)
      }.not_to change(AlbumCredit, :count)

      expect(response).to redirect_to(root_path)
    end
  end
end
