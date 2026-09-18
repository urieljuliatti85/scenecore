require "rails_helper"

RSpec.describe "Ticket check-ins", type: :request do
  it "lets a member of the event band validate an unused ticket" do
    ticket = create(:ticket)
    member = create(:user)
    create(:band_membership, user: member, band: ticket.event.band)
    sign_in member

    patch ticket_check_in_path(ticket.public_token)

    expect(response).to redirect_to(ticket_check_in_path(ticket.public_token))
    expect(ticket.reload).to be_used
  end

  it "rejects a second validation and preserves the first validator" do
    ticket = create(:ticket)
    first = create(:user)
    second = create(:user)
    create(:band_membership, user: first, band: ticket.event.band)
    create(:band_membership, user: second, band: ticket.event.band)
    TicketCheckIn.call(ticket, validator: first)
    sign_in second

    patch ticket_check_in_path(ticket.public_token)

    expect(response).to redirect_to(ticket_check_in_path(ticket.public_token))
    expect(ticket.reload.checked_in_by).to eq(first)
  end

  it "prevents a member of another band from seeing the check-in page" do
    ticket = create(:ticket)
    outsider = create(:user)
    create(:band_membership, user: outsider, band: create(:band))
    sign_in outsider

    get ticket_check_in_path(ticket.public_token)

    expect(response).to redirect_to(root_path)
  end
end
