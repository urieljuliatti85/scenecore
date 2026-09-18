require "rails_helper"

RSpec.describe "Ticket orders", type: :request do
  it "requires a fan to sign in before reserving tickets" do
    batch = create_public_batch

    post public_event_ticket_orders_path(batch.event.band.slug, batch.event),
         params: { ticket_batch_id: batch.id, quantity: 1 }

    expect(response).to redirect_to(new_user_session_path)
    expect(TicketOrder.count).to eq(0)
  end

  it "reserves tickets and redirects the signed-in fan to Stripe" do
    user = create(:user)
    batch = create_public_batch
    sign_in user
    allow(TicketCheckoutSessionCreator).to receive(:call).and_return("https://checkout.stripe.test/session")

    expect {
      post public_event_ticket_orders_path(batch.event.band.slug, batch.event),
           params: { ticket_batch_id: batch.id, quantity: 2 }
    }.to change(TicketOrder, :count).by(1)

    expect(response).to redirect_to("https://checkout.stripe.test/session")
    expect(TicketOrder.last.user).to eq(user)
    expect(TicketOrder.last.quantity).to eq(2)
  end

  it "issues free tickets without calling Stripe" do
    user = create(:user)
    batch = create_public_batch
    batch.update!(price_cents: 0)
    sign_in user
    allow(TicketCheckoutSessionCreator).to receive(:call)

    expect {
      post public_event_ticket_orders_path(batch.event.band.slug, batch.event),
           params: { ticket_batch_id: batch.id, quantity: 2 }
    }.to change(Ticket, :count).by(2)

    expect(TicketCheckoutSessionCreator).not_to have_received(:call)
    expect(response).to redirect_to(ticket_order_path(TicketOrder.last))
  end

  it "only shows an order to its purchaser" do
    order = create(:ticket_order)
    sign_in create(:user)

    get ticket_order_path(order)

    expect(response).to have_http_status(:not_found)
  end

  private

  def create_public_batch
    band = create(:band, :approved, :payouts_ready)
    event = create(:event, :published, band: band)
    create(:ticket_batch, event: event)
  end
end
