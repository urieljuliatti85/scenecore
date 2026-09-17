# Creates the Stripe Checkout Session that charges for a Store order and
# splits it in the same transaction (ADR-007): the band's connected account
# receives the payment, SceneCore takes `application_fee_amount`.
#
# This is a destination charge on the platform account, not a session
# created on the connected account, so the resulting event arrives on the
# platform's own webhook endpoint alongside the Subscription events —
# StripeWebhooksController tells them apart by which record owns the
# session id, not by the account the event came from.
class StoreCheckoutSessionCreator
  Error = Class.new(StandardError)

  # Matches what prices are displayed in across the platform. Changing this
  # without changing the displayed currency would charge a different amount
  # than the fan was shown.
  CURRENCY = "usd".freeze

  def self.call(order, success_url:, cancel_url:)
    new(order, success_url: success_url, cancel_url: cancel_url).call
  end

  def initialize(order, success_url:, cancel_url:)
    @order = order
    @success_url = success_url
    @cancel_url = cancel_url
  end

  def call
    band = @order.band
    raise Error, "#{band.name} can't take payments yet." unless band.payouts_ready?

    session = StripeClient.instance.v1.checkout.sessions.create(
      mode: "payment",
      line_items: line_items,
      payment_intent_data: {
        application_fee_amount: @order.platform_fee_cents,
        transfer_data: { destination: band.stripe_connect_account_id }
      },
      success_url: @success_url,
      cancel_url: @cancel_url,
      metadata: { order_id: @order.id, band_id: band.id, user_id: @order.user_id }
    )

    @order.update!(stripe_checkout_session_id: session.id)
    session.url
  rescue Stripe::StripeError => e
    raise Error, "Could not start checkout: #{e.message}"
  end

  private

  # Amounts come from the order's own snapshot rather than the live variant,
  # so what Stripe charges is exactly what the fan was shown and agreed to,
  # even if the band edits the product between placing and paying.
  def line_items
    items = @order.order_items.map do |item|
      {
        quantity: item.quantity,
        price_data: {
          currency: CURRENCY,
          unit_amount: item.unit_price_cents,
          product_data: { name: "#{item.product_name} — #{item.variant_name}" }
        }
      }
    end

    # Shipping is a line rather than a Stripe shipping_option because the
    # amount is already settled on the order; presenting it as an option
    # would invite Stripe to recalculate it.
    if @order.shipping_cents.positive?
      items << {
        quantity: 1,
        price_data: {
          currency: CURRENCY,
          unit_amount: @order.shipping_cents,
          product_data: { name: "Shipping" }
        }
      }
    end

    items
  end
end
