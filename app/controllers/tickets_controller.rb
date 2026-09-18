class TicketsController < ApplicationController
  def index
    @tickets = current_user.tickets.includes(event: :band).order(created_at: :desc)
  end

  def show
    @ticket = current_user.tickets.includes(event: :band, ticket_order: :ticket_batch).find_by!(public_token: params[:public_token])
    authorize @ticket
  end
end
