require "rails_helper"

RSpec.describe "Tickets", type: :request do
  it "shows the QR code only to the ticket owner" do
    ticket = create(:ticket)
    sign_in ticket.user

    get ticket_path(ticket.public_token)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("<svg")
    expect(response.body).to include("<path")
    expect(response.body).to include("Ready for check-in")
  end

  it "does not expose a ticket to another user" do
    ticket = create(:ticket)
    sign_in create(:user)

    get ticket_path(ticket.public_token)

    expect(response).to have_http_status(:not_found)
  end
end
