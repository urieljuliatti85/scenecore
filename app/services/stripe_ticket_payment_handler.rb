class StripeTicketPaymentHandler
  def self.call(session)
    new(session).call
  end

  def initialize(session)
    @session = session
  end

  def call
    return unless @session.payment_status.in?(%w[paid no_payment_required])

    order = TicketOrder.find_by(stripe_checkout_session_id: @session.id)
    order ||= order_from_metadata
    return if order.nil?

    # A very fast Stripe webhook can arrive before the request that created
    # the Checkout Session has persisted its id. Metadata is signed as part
    # of the event and points back to the order we created; record the id here
    # so later deliveries use the normal lookup. Never replace a different id.
    return if order.stripe_checkout_session_id.present? && order.stripe_checkout_session_id != @session.id

    order.update!(stripe_checkout_session_id: @session.id) if order.stripe_checkout_session_id.blank?

    TicketOrderFulfiller.call(order, payment_intent_id: payment_intent_id)
  end

  private

  def order_from_metadata
    order_id = @session.metadata&.[]("ticket_order_id")
    TicketOrder.find_by(id: order_id) if order_id.present?
  end

  def payment_intent_id
    value = @session.payment_intent
    value.respond_to?(:id) ? value.id : value
  end
end
