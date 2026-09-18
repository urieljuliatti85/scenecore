class TicketBatchesController < ApplicationController
  before_action :set_band_and_event
  before_action :set_ticket_batch, only: [ :edit, :update, :destroy ]

  def new
    @ticket_batch = @event.ticket_batches.new
    authorize @ticket_batch
  end

  def create
    @ticket_batch = @event.ticket_batches.new(ticket_batch_params)
    authorize @ticket_batch

    if @ticket_batch.save
      redirect_to band_event_path(@band, @event), notice: "Ticket batch created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @ticket_batch
  end

  def update
    authorize @ticket_batch

    updated = @ticket_batch.with_lock { @ticket_batch.update(ticket_batch_params) }

    if updated
      redirect_to band_event_path(@band, @event), notice: "Ticket batch updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @ticket_batch

    if @ticket_batch.destroy
      redirect_to band_event_path(@band, @event), notice: "Ticket batch deleted."
    else
      redirect_to band_event_path(@band, @event), alert: @ticket_batch.errors.full_messages.to_sentence
    end
  end

  private

  def set_band_and_event
    @band = Band.find(params[:band_id])
    @event = @band.events.find(params[:event_id])
  end

  def set_ticket_batch
    @ticket_batch = @event.ticket_batches.find(params[:id])
  end

  def ticket_batch_params
    params.require(:ticket_batch).permit(:name, :price_cents, :quantity_total, :sales_start_at, :sales_end_at)
  end
end
