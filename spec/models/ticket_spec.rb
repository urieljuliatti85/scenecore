require "rails_helper"

RSpec.describe Ticket, type: :model do
  it "assigns an opaque unique public token" do
    ticket = create(:ticket)

    expect(ticket.public_token).to be_present
    expect(ticket.public_token.length).to be >= 32
    expect(ticket.public_token).not_to eq(ticket.id.to_s)
  end

  it "cannot point at another order's purchaser or event" do
    order = create(:ticket_order, :paid)
    ticket = build(:ticket, ticket_order: order, user: create(:user))

    expect(ticket).not_to be_valid
    expect(ticket.errors[:user]).to include("must match the ticket order purchaser")
  end
end
