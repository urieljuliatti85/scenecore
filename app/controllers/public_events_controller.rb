class PublicEventsController < ApplicationController
  skip_before_action :authenticate_user!

  def show
    @band = Band.approved.find_by!(slug: params[:slug])
    @event = @band.events.published.upcoming.find(params[:id])
    @ticket_batches = @event.ticket_batches.for_sale
  rescue ActiveRecord::RecordNotFound
    render "public_bands/not_found", status: :not_found
  end
end
