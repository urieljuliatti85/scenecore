class TicketCheckoutSessionCreator
  Error = Class.new(StandardError)
  CURRENCY = "usd".freeze

  def self.call(ticket_order, success_url:, cancel_url:)
    new(ticket_order, success_url: success_url, cancel_url: cancel_url).call
  end

  def initialize(ticket_order, success_url:, cancel_url:)
    @ticket_order = ticket_order
    @success_url = success_url
    @cancel_url = cancel_url
  end

  def call
    raise Error, "#{@ticket_order.band.name} can't take payments yet." unless @ticket_order.band.payouts_ready?

    session = StripeClient.instance.v1.checkout.sessions.create(
      mode: "payment",
      line_items: [ {
        quantity: @ticket_order.quantity,
        price_data: {
          currency: CURRENCY,
          unit_amount: @ticket_order.unit_price_cents,
          product_data: { name: "#{@ticket_order.event.title} — #{@ticket_order.ticket_batch.name}" }
        }
      } ],
      payment_intent_data: {
        application_fee_amount: @ticket_order.platform_fee_cents,
        transfer_data: { destination: @ticket_order.band.stripe_connect_account_id }
      },
      expires_at: @ticket_order.expires_at.to_i,
      success_url: @success_url,
      cancel_url: @cancel_url,
      metadata: {
        ticket_order_id: @ticket_order.id,
        event_id: @ticket_order.event.id,
        band_id: @ticket_order.band.id,
        user_id: @ticket_order.user_id
      }
    )

    @ticket_order.update!(stripe_checkout_session_id: session.id)
    session.url
  rescue Stripe::StripeError => e
    raise Error, "Could not start ticket checkout: #{e.message}"
  end
end
