require "rails_helper"

RSpec.describe "Band community", type: :request do
  let(:band) { create(:band, :approved) }

  describe "member access" do
    Membership::LEVELS.each do |level|
      it "allows an active #{level.humanize} to view and create topics" do
        user = create(:user)
        create(:membership, band: band, user: user, level: level)
        sign_in user

        get public_band_community_path(band.slug)
        expect(response).to have_http_status(:ok)

        expect {
          post community_topics_path(band.slug), params: {
            community_topic: { title: "Tour memories", body: "What was your favorite show?" }
          }
        }.to change(band.community_topics, :count).by(1)
      end
    end

    it "denies a user without a relationship to the band" do
      sign_in create(:user)

      get public_band_community_path(band.slug)

      expect(response).to redirect_to(root_path)
    end

    it "denies a paused member" do
      user = create(:user)
      create(:membership, :paused, band: band, user: user)
      sign_in user

      get public_band_community_path(band.slug)

      expect(response).to redirect_to(root_path)
    end

    it "requires authentication" do
      get public_band_community_path(band.slug)

      expect(response).to redirect_to(new_user_session_path)
    end

    it "does not expose topics through another band's URL" do
      user = create(:user)
      other_band = create(:band, :approved)
      create(:membership, band: other_band, user: user)
      topic = create(:community_topic, band: band)
      sign_in user

      get community_topic_path(other_band.slug, topic)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "conversation" do
    let(:user) { create(:user) }
    let!(:membership) { create(:membership, :supporter, band: band, user: user) }
    let(:topic) { create(:community_topic, band: band, user: user) }

    before { sign_in user }

    it "lets a member reply" do
      expect {
        post community_topic_replies_path(band.slug, topic), params: {
          community_reply: { body: "I loved the São Paulo show." }
        }
      }.to change(topic.community_replies, :count).by(1)

      expect(response).to redirect_to(community_topic_path(band.slug, topic))
    end

    it "shows membership badges" do
      get community_topic_path(band.slug, topic)

      expect(response.body).to include("Supporter")
    end

    it "lets a member report a topic and a reply" do
      reply = create(:community_reply, community_topic: topic)

      expect {
        post report_community_topic_path(band.slug, topic), params: { report: { reason: "Abusive" } }
        post report_community_reply_path(band.slug, topic, reply), params: { report: { reason: "Spam" } }
      }.to change(Report, :count).by(2)
    end
  end

  describe "moderation" do
    let(:author) { create(:user) }
    let(:topic) { create(:community_topic, band: band, user: author) }

    it "lets the author delete their topic" do
      create(:membership, band: band, user: author)
      sign_in author
      topic

      expect {
        delete community_topic_path(band.slug, topic)
      }.to change(CommunityTopic, :count).by(-1)
    end

    it "lets a band administrator moderate only their own band" do
      administrator = create(:user)
      create(:band_membership, :administrator, band: band, user: administrator)
      other_band = create(:band, :approved)
      other_topic = create(:community_topic, band: other_band)
      sign_in administrator

      delete community_topic_path(band.slug, topic)
      expect(response).to redirect_to(public_band_community_path(band.slug))

      expect {
        delete community_topic_path(other_band.slug, other_topic)
      }.not_to change(CommunityTopic, :count)
      expect(response).to redirect_to(root_path)
    end

    it "records platform moderation" do
      administrator = create(:user, :platform_admin)
      sign_in administrator
      topic

      expect {
        delete community_topic_path(band.slug, topic)
      }.to change(AdminActionLog, :count).by(1)

      expect(AdminActionLog.last.action).to eq("moderate_delete_community_topic")
    end
  end
end
