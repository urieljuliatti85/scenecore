class PollVotesController < ApplicationController
  before_action :set_poll

  rescue_from ActiveRecord::RecordNotFound do
    head :not_found
  end

  def upsert
    authorize @poll, :upsert?, policy_class: PollVotePolicy

    option_ids = Array(params.dig(:poll_vote, :option_ids)).reject(&:blank?).map(&:to_i)
    options = @poll.poll_options.where(id: option_ids)

    if options.empty?
      return redirect_to public_poll_path, alert: "Select an option to vote."
    end

    if !@poll.allow_multiple_choices? && options.size > 1
      return redirect_to public_poll_path, alert: "This poll only allows one choice."
    end

    already_voted = @poll.voted_by?(current_user)
    if already_voted && !@poll.allow_vote_change?
      return redirect_to public_poll_path, alert: "You've already voted in this poll."
    end

    ActiveRecord::Base.transaction do
      PollVote.where(user: current_user, poll_option: @poll.poll_options).destroy_all
      options.each { |option| PollVote.create!(user: current_user, poll_option: option) }
    end

    redirect_to public_poll_path, notice: "Thanks for voting."
  end

  private

  def set_poll
    band = Band.approved.find_by!(slug: params[:slug])
    @poll = band.polls.published.find(params[:poll_id])
  end

  def public_poll_path
    public_band_path(params[:slug])
  end
end
