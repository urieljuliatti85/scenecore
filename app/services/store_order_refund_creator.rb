# Starts the only Store refund supported in the MVP: a full refund of the
# fan's payment, including shipping, while also reversing the band's Connect
# transfer and SceneCore's application fee.
class StoreOrderRefundCreator
  Error = Class.new(StandardError)

  def self.call(order)
    new(order).call
  end

  def initialize(order)
    @order = order
  end

  def call
    @order.with_lock do
      raise Error, "This order can't be refunded." unless @order.refundable?

      payment_intent_id = resolve_payment_intent_id
      raise Error, "Stripe has no payment to refund for this order." if payment_intent_id.blank?

      refund = StripeClient.instance.v1.refunds.create(
        {
          payment_intent: payment_intent_id,
          reverse_transfer: true,
          refund_application_fee: true,
          reason: "requested_by_customer",
          metadata: { order_id: @order.id, band_id: @order.band_id }
        },
        { idempotency_key: "store-order-refund-#{@order.id}" }
      )

      @order.update!(
        stripe_payment_intent_id: payment_intent_id,
        stripe_refund_id: refund.id,
        refund_status: refund.status
      )
    end

    @order
  rescue Stripe::StripeError => e
    raise Error, "Stripe could not start the refund: #{e.message}"
  end

  private

  def resolve_payment_intent_id
    return @order.stripe_payment_intent_id if @order.stripe_payment_intent_id.present?

    session = StripeClient.instance.v1.checkout.sessions.retrieve(@order.stripe_checkout_session_id)
    session.payment_intent.respond_to?(:id) ? session.payment_intent.id : session.payment_intent
  end
end
