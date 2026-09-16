require "rails_helper"

RSpec.describe "Poll votes", type: :request do
  describe "PUT /:slug/polls/:poll_id/vote" do
    it "allows a signed-in user to vote in an open, single-choice poll" do
      band = create(:band, :approved)
      poll = create(:poll, :published, band: band)
      option = poll.poll_options.first
      user = create(:user)
      sign_in user

      expect {
        put poll_vote_path(band.slug, poll), params: { poll_vote: { option_ids: [ option.id ] } }
      }.to change(PollVote, :count).by(1)

      expect(PollVote.last.poll_option).to eq(option)
    end

    it "rejects multiple selections when the poll does not allow multiple choices" do
      band = create(:band, :approved)
      poll = create(:poll, :published, band: band, allow_multiple_choices: false)
      user = create(:user)
      sign_in user

      expect {
        put poll_vote_path(band.slug, poll),
            params: { poll_vote: { option_ids: poll.poll_options.map(&:id) } }
      }.not_to change(PollVote, :count)
    end

    it "allows multiple selections when the poll allows multiple choices" do
      band = create(:band, :approved)
      poll = create(:poll, :published, band: band, allow_multiple_choices: true)
      user = create(:user)
      sign_in user

      expect {
        put poll_vote_path(band.slug, poll),
            params: { poll_vote: { option_ids: poll.poll_options.map(&:id) } }
      }.to change(PollVote, :count).by(2)
    end

    it "does not allow voting again when allow_vote_change is false" do
      band = create(:band, :approved)
      poll = create(:poll, :published, band: band, allow_vote_change: false)
      user = create(:user)
      create(:poll_vote, user: user, poll_option: poll.poll_options.first)
      sign_in user

      expect {
        put poll_vote_path(band.slug, poll),
            params: { poll_vote: { option_ids: [ poll.poll_options.second.id ] } }
      }.not_to change(PollVote, :count)

      expect(poll.poll_options.first.reload.poll_votes).not_to be_empty
    end

    it "replaces the previous vote when allow_vote_change is true" do
      band = create(:band, :approved)
      poll = create(:poll, :published, band: band, allow_vote_change: true)
      first_option = poll.poll_options.first
      second_option = poll.poll_options.second
      user = create(:user)
      create(:poll_vote, user: user, poll_option: first_option)
      sign_in user

      put poll_vote_path(band.slug, poll), params: { poll_vote: { option_ids: [ second_option.id ] } }

      expect(first_option.reload.poll_votes).to be_empty
      expect(second_option.reload.poll_votes.map(&:user)).to contain_exactly(user)
    end

    it "requires authentication" do
      band = create(:band, :approved)
      poll = create(:poll, :published, band: band)

      put poll_vote_path(band.slug, poll), params: { poll_vote: { option_ids: [ poll.poll_options.first.id ] } }

      expect(response).to redirect_to(new_user_session_path)
    end

    it "does not allow voting in a draft poll" do
      band = create(:band, :approved)
      poll = create(:poll, band: band)
      user = create(:user)
      sign_in user

      put poll_vote_path(band.slug, poll), params: { poll_vote: { option_ids: [ poll.poll_options.first.id ] } }

      expect(response).to have_http_status(:not_found)
    end

    it "does not allow voting when the required membership level is not met" do
      band = create(:band, :approved)
      poll = create(:poll, :published, :fan_only, band: band)
      user = create(:user)
      sign_in user

      expect {
        put poll_vote_path(band.slug, poll), params: { poll_vote: { option_ids: [ poll.poll_options.first.id ] } }
      }.not_to change(PollVote, :count)
    end
  end
end
