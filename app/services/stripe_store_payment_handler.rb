# Marks a Store order paid once Stripe confirms its Checkout Session
# completed, and consumes the stock that order claimed.
#
# Fulfillment belongs here rather than on the success page: the buyer can
# close the tab before being redirected, and the redirect can fail without
# the payment being affected either way.
class StripeStorePaymentHandler
  def self.call(session)
    new(session).call
  end

  def initialize(session)
    @session = session
  end

  def call
    return unless @session.payment_status.in?(%w[paid no_payment_required])

    order = Order.find_by(stripe_checkout_session_id: @session.id)
    return if order.nil?

    # Stripe retries a webhook until it gets a 2xx, and the same event can
    # arrive more than once. Decrementing stock again for an order already
    # marked paid would sell inventory the buyer never bought.
    return unless order.pending?

    ActiveRecord::Base.transaction do
      order.order_items.each do |item|
        begin
          item.product_variant&.decrement_stock!(item.quantity)
        rescue ProductVariant::InsufficientStock => e
          # Stock went while the fan was paying. The money is already taken,
          # so the order is still recorded as paid and the shortfall is
          # logged for the band to resolve — dropping the order here would
          # lose a paid purchase, and re-raising would have Stripe retry
          # this webhook indefinitely against an outcome that will not
          # change.
          Rails.logger.error("Store order #{order.id}: #{e.message}")
        end
      end

      order.update!(status: :paid, stripe_payment_intent_id: payment_intent_id)
    end
  end

  private

  def payment_intent_id
    value = @session.payment_intent
    value.respond_to?(:id) ? value.id : value
  end
end
