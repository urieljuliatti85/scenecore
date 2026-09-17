require "rails_helper"

RSpec.describe "Direct Messages (band replies)", type: :request do
  describe "POST /bands/:band_id/direct_message_threads/:direct_message_thread_id/direct_messages" do
    it "lets a band member reply in the thread" do
      band = create(:band)
      member = create(:user)
      create(:band_membership, band: band, user: member)
      thread = create(:direct_message_thread, band: band)
      sign_in member

      expect {
        post band_direct_message_thread_direct_messages_path(band, thread), params: { direct_message: { body: "Thanks for reaching out!" } }
      }.to change(DirectMessage, :count).by(1)

      message = DirectMessage.last
      expect(message.sent_by_band).to be true
      expect(message.user).to eq(member)
      expect(response).to redirect_to(band_direct_message_thread_path(band, thread))
    end

    it "lets a band member reply even when the thread is blocked" do
      band = create(:band)
      member = create(:user)
      create(:band_membership, band: band, user: member)
      thread = create(:direct_message_thread, :blocked, band: band)
      sign_in member

      expect {
        post band_direct_message_thread_direct_messages_path(band, thread), params: { direct_message: { body: "One more thing..." } }
      }.to change(DirectMessage, :count).by(1)
    end

    it "prevents a member of another band from replying" do
      band = create(:band)
      thread = create(:direct_message_thread, band: band)
      outsider = create(:user)
      create(:band_membership, band: create(:band), user: outsider)
      sign_in outsider

      expect {
        post band_direct_message_thread_direct_messages_path(band, thread), params: { direct_message: { body: "Hi" } }
      }.not_to change(DirectMessage, :count)

      expect(response).to redirect_to(root_path)
    end

    it "requires authentication" do
      band = create(:band)
      thread = create(:direct_message_thread, band: band)

      post band_direct_message_thread_direct_messages_path(band, thread), params: { direct_message: { body: "Hi" } }

      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
