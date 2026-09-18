class TicketCheckInsController < ApplicationController
  before_action :set_ticket

  def show
    authorize @ticket, :check_in?
  end

  def update
    authorize @ticket, :check_in?
    TicketCheckIn.call(@ticket, validator: current_user)
    redirect_to ticket_check_in_path(@ticket.public_token), notice: "Ticket checked in."
  rescue TicketCheckIn::AlreadyUsed => e
    redirect_to ticket_check_in_path(@ticket.public_token), alert: e.message
  end

  private

  def set_ticket
    @ticket = Ticket.includes(:user, event: :band).find_by!(public_token: params[:public_token])
  end
end
