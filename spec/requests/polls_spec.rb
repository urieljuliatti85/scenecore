require "rails_helper"

RSpec.describe "Polls", type: :request do
  describe "GET /bands/:band_id/polls/:id" do
    it "requires authentication" do
      poll = create(:poll)

      get band_poll_path(poll.band, poll)

      expect(response).to redirect_to(new_user_session_path)
    end

    it "shows the poll to a band member" do
      user = create(:user)
      band = create(:band)
      create(:band_membership, band: band, user: user)
      poll = create(:poll, band: band, question: "Which song should we play live?")
      sign_in user

      get band_poll_path(band, poll)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Which song should we play live?")
    end

    it "prevents a member of another band from viewing the poll" do
      outsider = create(:user)
      create(:band_membership, band: create(:band), user: outsider)
      poll = create(:poll)
      sign_in outsider

      get band_poll_path(poll.band, poll)

      expect(response).to redirect_to(root_path)
    end
  end

  describe "POST /bands/:band_id/polls" do
    it "allows a band member to create a poll with options" do
      user = create(:user)
      band = create(:band)
      create(:band_membership, band: band, user: user)
      sign_in user

      expect {
        post band_polls_path(band), params: {
          poll: {
            question: "Which cover should we play?",
            visibility: "public",
            poll_options_attributes: {
              "0" => { label: "Song A" },
              "1" => { label: "Song B" }
            }
          }
        }
      }.to change(Poll, :count).by(1)

      poll = Poll.last
      expect(poll.question).to eq("Which cover should we play?")
      expect(poll.poll_options.pluck(:label)).to contain_exactly("Song A", "Song B")
    end

    it "rejects a poll with fewer than two options" do
      user = create(:user)
      band = create(:band)
      create(:band_membership, band: band, user: user)
      sign_in user

      expect {
        post band_polls_path(band), params: {
          poll: {
            question: "Which cover should we play?",
            poll_options_attributes: { "0" => { label: "Only one" } }
          }
        }
      }.not_to change(Poll, :count)

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "does not allow a non-member to create a poll" do
      user = create(:user)
      band = create(:band)
      sign_in user

      expect {
        post band_polls_path(band), params: { poll: { question: "Q?" } }
      }.not_to change(Poll, :count)
    end
  end

  describe "PATCH /bands/:band_id/polls/:id/publish" do
    it "allows a band member to publish a poll" do
      user = create(:user)
      band = create(:band)
      create(:band_membership, band: band, user: user)
      poll = create(:poll, band: band)
      sign_in user

      patch publish_band_poll_path(band, poll)

      expect(poll.reload).to be_published
    end
  end

  describe "PATCH /bands/:band_id/polls/:id/unpublish" do
    it "allows a band member to unpublish a poll" do
      user = create(:user)
      band = create(:band)
      create(:band_membership, band: band, user: user)
      poll = create(:poll, :published, band: band)
      sign_in user

      patch unpublish_band_poll_path(band, poll)

      expect(poll.reload).to be_draft
    end
  end

  describe "DELETE /bands/:band_id/polls/:id" do
    it "allows a band member to delete a poll" do
      user = create(:user)
      band = create(:band)
      create(:band_membership, band: band, user: user)
      poll = create(:poll, band: band)
      sign_in user

      expect {
        delete band_poll_path(band, poll)
      }.to change(Poll, :count).by(-1)
    end

    it "does not allow a member of another band to delete the poll" do
      outsider = create(:user)
      create(:band_membership, band: create(:band), user: outsider)
      poll = create(:poll)
      sign_in outsider

      expect {
        delete band_poll_path(poll.band, poll)
      }.not_to change(Poll, :count)
    end
  end
end
