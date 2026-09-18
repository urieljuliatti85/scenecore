class EventsController < ApplicationController
  before_action :set_band
  before_action :set_event, only: [ :show, :edit, :update, :destroy, :publish, :unpublish ]

  def new
    @event = @band.events.new
    authorize @event
  end

  def show
    authorize @event
    @ticket_batches = @event.ticket_batches.for_sale
  end

  def create
    @event = @band.events.new(event_params)
    authorize @event

    if @event.save
      redirect_to band_path(@band), notice: "Event created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @event
  end

  def update
    authorize @event

    if @event.update(event_params)
      redirect_to band_path(@band), notice: "Event updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @event

    if @event.destroy
      redirect_to band_path(@band), notice: "Event deleted."
    else
      redirect_to band_event_path(@band, @event), alert: @event.errors.full_messages.to_sentence
    end
  end

  def publish
    authorize @event

    @event.published!
    redirect_to band_path(@band), notice: "Event published."
  end

  def unpublish
    authorize @event

    @event.draft!
    redirect_to band_path(@band), notice: "Event unpublished."
  end

  private

  def set_band
    @band = Band.find(params[:band_id])
  end

  def set_event
    @event = @band.events.find(params[:id])
  end

  def event_params
    params.require(:event).permit(:title, :location, :starts_at, :ticket_url, :description)
  end
end
