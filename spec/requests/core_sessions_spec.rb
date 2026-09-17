require "rails_helper"

RSpec.describe "Core Sessions", type: :request do
  describe "POST /bands/:band_id/core_sessions" do
    it "creates a core session for a band member" do
      user = create(:user)
      band = create(:band)
      create(:band_membership, band: band, user: user)
      sign_in user

      expect {
        post band_core_sessions_path(band), params: { core_session: { title: "Listening Party", session_type: "listening_party", starts_at: 1.week.from_now, capacity: 20 } }
      }.to change(CoreSession, :count).by(1)

      expect(CoreSession.last.band).to eq(band)
      expect(response).to redirect_to(band_path(band))
    end

    it "prevents a member of another band from creating a session" do
      band = create(:band)
      outsider = create(:user)
      create(:band_membership, band: create(:band), user: outsider)
      sign_in outsider

      expect {
        post band_core_sessions_path(band), params: { core_session: { title: "Listening Party", session_type: "listening_party", starts_at: 1.week.from_now } }
      }.not_to change(CoreSession, :count)

      expect(response).to redirect_to(root_path)
    end

    it "does not create a session without a title" do
      user = create(:user)
      band = create(:band)
      create(:band_membership, band: band, user: user)
      sign_in user

      expect {
        post band_core_sessions_path(band), params: { core_session: { title: "", session_type: "qa", starts_at: 1.week.from_now } }
      }.not_to change(CoreSession, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "PATCH /bands/:band_id/core_sessions/:id/publish" do
    it "publishes the session" do
      user = create(:user)
      band = create(:band)
      create(:band_membership, band: band, user: user)
      session = create(:core_session, band: band)
      sign_in user

      patch publish_band_core_session_path(band, session)

      expect(session.reload.status).to eq("published")
    end
  end

  describe "PATCH /bands/:band_id/core_sessions/:id/unpublish" do
    it "unpublishes the session" do
      user = create(:user)
      band = create(:band)
      create(:band_membership, band: band, user: user)
      session = create(:core_session, :published, band: band)
      sign_in user

      patch unpublish_band_core_session_path(band, session)

      expect(session.reload.status).to eq("draft")
    end
  end

  describe "DELETE /bands/:band_id/core_sessions/:id" do
    it "allows a band member to delete a session" do
      user = create(:user)
      band = create(:band)
      create(:band_membership, band: band, user: user)
      session = create(:core_session, band: band)
      sign_in user

      expect {
        delete band_core_session_path(band, session)
      }.to change(CoreSession, :count).by(-1)
    end

    it "prevents a member of another band from deleting the session" do
      band = create(:band)
      session = create(:core_session, band: band)
      outsider = create(:user)
      create(:band_membership, band: create(:band), user: outsider)
      sign_in outsider

      expect {
        delete band_core_session_path(band, session)
      }.not_to change(CoreSession, :count)

      expect(response).to redirect_to(root_path)
    end
  end
end
