class PollsController < ApplicationController
  before_action :set_band
  before_action :set_poll, only: [ :show, :edit, :update, :destroy, :publish, :unpublish ]

  def new
    @poll = @band.polls.new
    3.times { @poll.poll_options.build }
    authorize @poll
  end

  def show
    authorize @poll
  end

  def create
    @poll = @band.polls.new(poll_params)
    authorize @poll

    if @poll.save
      redirect_to band_path(@band), notice: "Poll created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @poll
    @poll.poll_options.build if @poll.poll_options.size < 2
  end

  def update
    authorize @poll

    if @poll.update(poll_params)
      redirect_to band_path(@band), notice: "Poll updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @poll

    @poll.destroy
    redirect_to band_path(@band), notice: "Poll deleted."
  end

  def publish
    authorize @poll

    @poll.published!
    redirect_to band_path(@band), notice: "Poll published."
  end

  def unpublish
    authorize @poll

    @poll.draft!
    redirect_to band_path(@band), notice: "Poll unpublished."
  end

  private

  def set_band
    @band = Band.find(params[:band_id])
  end

  def set_poll
    @poll = @band.polls.find(params[:id])
  end

  def poll_params
    params.require(:poll).permit(
      :question, :visibility, :allow_multiple_choices, :allow_vote_change, :opens_at, :closes_at,
      poll_options_attributes: [ :id, :label, :position, :_destroy ]
    )
  end
end
