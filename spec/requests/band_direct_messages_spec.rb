require "rails_helper"

RSpec.describe "Band Direct Messages (Core Member view)", type: :request do
  describe "GET /:slug/messages" do
    it "shows the thread to a Core Member" do
      band = create(:band, :approved)
      user = create(:user)
      create(:membership, :core_member, band: band, user: user)
      thread = create(:direct_message_thread, band: band, user: user)
      create(:direct_message, direct_message_thread: thread, user: user, body: "Hi there!")
      sign_in user

      get my_band_direct_messages_path(band.slug)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Hi there!")
    end

    it "redirects a Supporter to the band's page" do
      band = create(:band, :approved)
      user = create(:user)
      create(:membership, :supporter, band: band, user: user)
      sign_in user

      get my_band_direct_messages_path(band.slug)

      expect(response).to redirect_to(public_band_path(band.slug))
    end

    it "requires authentication" do
      band = create(:band, :approved)

      get my_band_direct_messages_path(band.slug)

      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "POST /:slug/messages" do
    it "creates a thread and message on first contact" do
      band = create(:band, :approved)
      user = create(:user)
      create(:membership, :core_member, band: band, user: user)
      sign_in user

      expect {
        post my_band_direct_messages_path(band.slug), params: { direct_message: { body: "When's the next release?" } }
      }.to change(DirectMessageThread, :count).by(1).and change(DirectMessage, :count).by(1)

      message = DirectMessage.last
      expect(message.sent_by_band).to be false
      expect(message.user).to eq(user)
      expect(response).to redirect_to(my_band_direct_messages_path(band.slug))
    end

    it "reuses the existing thread on a second message" do
      band = create(:band, :approved)
      user = create(:user)
      create(:membership, :core_member, band: band, user: user)
      create(:direct_message_thread, band: band, user: user)
      sign_in user

      expect {
        post my_band_direct_messages_path(band.slug), params: { direct_message: { body: "Following up..." } }
      }.to change(DirectMessage, :count).by(1).and change(DirectMessageThread, :count).by(0)
    end

    it "does not let a Supporter send a message" do
      band = create(:band, :approved)
      user = create(:user)
      create(:membership, :supporter, band: band, user: user)
      sign_in user

      expect {
        post my_band_direct_messages_path(band.slug), params: { direct_message: { body: "Hello?" } }
      }.not_to change(DirectMessage, :count)
    end

    it "does not let a blocked Core Member send a message" do
      band = create(:band, :approved)
      user = create(:user)
      create(:membership, :core_member, band: band, user: user)
      create(:direct_message_thread, :blocked, band: band, user: user)
      sign_in user

      expect {
        post my_band_direct_messages_path(band.slug), params: { direct_message: { body: "Hello?" } }
      }.not_to change(DirectMessage, :count)
    end

    it "rejects a message over 2000 characters" do
      band = create(:band, :approved)
      user = create(:user)
      create(:membership, :core_member, band: band, user: user)
      sign_in user

      expect {
        post my_band_direct_messages_path(band.slug), params: { direct_message: { body: "a" * 2001 } }
      }.not_to change(DirectMessage, :count)
    end
  end
end
