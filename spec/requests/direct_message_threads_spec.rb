require "rails_helper"

RSpec.describe "Direct Message Threads (band inbox)", type: :request do
  describe "GET /bands/:band_id/direct_message_threads" do
    it "lists threads for a band member" do
      band = create(:band)
      member = create(:user)
      create(:band_membership, band: band, user: member)
      core_member = create(:user, name: "Alex Core")
      create(:direct_message_thread, band: band, user: core_member)
      sign_in member

      get band_direct_message_threads_path(band)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Alex Core")
    end

    it "prevents a member of another band from viewing the inbox" do
      band = create(:band)
      outsider = create(:user)
      create(:band_membership, band: create(:band), user: outsider)
      sign_in outsider

      get band_direct_message_threads_path(band)

      expect(response).to redirect_to(root_path)
    end

    it "requires authentication" do
      band = create(:band)

      get band_direct_message_threads_path(band)

      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "GET /bands/:band_id/direct_message_threads/:id" do
    it "shows the thread's messages to a band member" do
      band = create(:band)
      member = create(:user)
      create(:band_membership, band: band, user: member)
      thread = create(:direct_message_thread, band: band)
      create(:direct_message, direct_message_thread: thread, body: "When is the album out?")
      sign_in member

      get band_direct_message_thread_path(band, thread)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("When is the album out?")
    end

    it "prevents a member of another band from viewing the thread" do
      band = create(:band)
      thread = create(:direct_message_thread, band: band)
      outsider = create(:user)
      create(:band_membership, band: create(:band), user: outsider)
      sign_in outsider

      get band_direct_message_thread_path(band, thread)

      expect(response).to redirect_to(root_path)
    end
  end

  describe "PATCH /bands/:band_id/direct_message_threads/:id/archive" do
    it "archives the thread for a band member" do
      band = create(:band)
      member = create(:user)
      create(:band_membership, band: band, user: member)
      thread = create(:direct_message_thread, band: band)
      sign_in member

      patch archive_band_direct_message_thread_path(band, thread)

      expect(thread.reload.status).to eq("archived")
    end
  end

  describe "PATCH /bands/:band_id/direct_message_threads/:id/block" do
    it "blocks the thread for a band member" do
      band = create(:band)
      member = create(:user)
      create(:band_membership, band: band, user: member)
      thread = create(:direct_message_thread, band: band)
      sign_in member

      patch block_band_direct_message_thread_path(band, thread)

      expect(thread.reload.status).to eq("blocked")
    end

    it "does not log an audit entry when the band blocks its own thread" do
      band = create(:band)
      member = create(:user)
      create(:band_membership, band: band, user: member)
      thread = create(:direct_message_thread, band: band)
      sign_in member

      expect {
        patch block_band_direct_message_thread_path(band, thread)
      }.not_to change(AdminActionLog, :count)
    end

    it "logs an audit entry when a platform admin blocks another band's thread" do
      band = create(:band)
      thread = create(:direct_message_thread, band: band)
      admin = create(:user, :platform_admin)
      sign_in admin

      patch block_band_direct_message_thread_path(band, thread)

      log = AdminActionLog.last
      expect(log.action).to eq("moderate_block_direct_message_thread")
      expect(log.actor).to eq(admin)
    end
  end

  describe "PATCH /bands/:band_id/direct_message_threads/:id/unblock" do
    it "reopens a blocked thread for a band member" do
      band = create(:band)
      member = create(:user)
      create(:band_membership, band: band, user: member)
      thread = create(:direct_message_thread, :blocked, band: band)
      sign_in member

      patch unblock_band_direct_message_thread_path(band, thread)

      expect(thread.reload.status).to eq("open")
    end
  end
end
