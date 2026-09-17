require "rails_helper"

RSpec.describe "Core Session RSVPs", type: :request do
  describe "POST /:slug/core_sessions/:core_session_id/rsvp" do
    it "lets a Core Member RSVP to a published session" do
      band = create(:band, :approved)
      session = create(:core_session, :published, band: band, capacity: 5)
      user = create(:user)
      create(:membership, :core_member, band: band, user: user)
      sign_in user

      expect {
        post core_session_rsvp_path(band.slug, session)
      }.to change(CoreSessionRsvp, :count).by(1)

      expect(response).to redirect_to(public_band_path(band.slug))
    end

    it "does not let a Supporter RSVP" do
      band = create(:band, :approved)
      session = create(:core_session, :published, band: band)
      user = create(:user)
      create(:membership, :supporter, band: band, user: user)
      sign_in user

      expect {
        post core_session_rsvp_path(band.slug, session)
      }.not_to change(CoreSessionRsvp, :count)
    end

    it "does not let a Core Member RSVP to a fully booked session" do
      band = create(:band, :approved)
      session = create(:core_session, :published, band: band, capacity: 1)
      attendee = create(:user)
      create(:membership, :core_member, band: band, user: attendee)
      create(:core_session_rsvp, core_session: session, user: attendee)

      latecomer = create(:user)
      create(:membership, :core_member, band: band, user: latecomer)
      sign_in latecomer

      expect {
        post core_session_rsvp_path(band.slug, session)
      }.not_to change(CoreSessionRsvp, :count)
    end

    it "returns 404 for a draft session" do
      band = create(:band, :approved)
      session = create(:core_session, band: band)
      user = create(:user)
      create(:membership, :core_member, band: band, user: user)
      sign_in user

      post core_session_rsvp_path(band.slug, session)

      expect(response).to have_http_status(:not_found)
    end

    it "requires authentication" do
      band = create(:band, :approved)
      session = create(:core_session, :published, band: band)

      post core_session_rsvp_path(band.slug, session)

      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "DELETE /:slug/core_sessions/:core_session_id/rsvp" do
    it "cancels the current user's RSVP" do
      band = create(:band, :approved)
      session = create(:core_session, :published, band: band)
      user = create(:user)
      create(:membership, :core_member, band: band, user: user)
      create(:core_session_rsvp, core_session: session, user: user)
      sign_in user

      expect {
        delete cancel_core_session_rsvp_path(band.slug, session)
      }.to change(CoreSessionRsvp, :count).by(-1)
    end

    it "returns 404 when the user has no RSVP to cancel" do
      band = create(:band, :approved)
      session = create(:core_session, :published, band: band)
      user = create(:user)
      create(:membership, :core_member, band: band, user: user)
      sign_in user

      delete cancel_core_session_rsvp_path(band.slug, session)

      expect(response).to have_http_status(:not_found)
    end
  end
end
