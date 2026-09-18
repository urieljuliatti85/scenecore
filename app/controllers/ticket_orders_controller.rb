class TicketOrdersController < ApplicationController
  def create
    band = Band.approved.find_by!(slug: params[:slug])
    event = band.events.published.upcoming.find(params[:event_id])
    batch = event.ticket_batches.find(params.require(:ticket_batch_id))

    order = TicketOrderCreator.call(
      user: current_user,
      ticket_batch: batch,
      quantity: params.require(:quantity)
    )

    if order.total_cents.zero?
      TicketOrderFulfiller.call(order)
      return redirect_to ticket_order_path(order), notice: "Your free tickets are ready."
    end

    url = TicketCheckoutSessionCreator.call(
      order,
      success_url: ticket_order_url(order),
      cancel_url: public_event_url(band.slug, event)
    )

    redirect_to url, allow_other_host: true
  rescue TicketOrderCreator::Error, TicketCheckoutSessionCreator::Error => e
    order&.destroy
    redirect_to public_event_path(params[:slug], params[:event_id]), alert: e.message
  end

  def show
    @ticket_order = current_user.ticket_orders.includes(:tickets, ticket_batch: { event: :band }).find(params[:id])
  end
end
