# Applies Stripe's signed refund events to a Store order. The initiating HTTP
# request records only that a refund was requested; Stripe's webhook remains
# the source of truth for the financial state transition.
class StripeStoreRefundHandler
  TERMINAL_STATUSES = %w[succeeded failed canceled].freeze

  def self.call(refund)
    new(refund).call
  end

  def initialize(refund)
    @refund = refund
  end

  def call
    order = find_order
    return if order.nil?

    order.with_lock do
      return if order.stripe_refund_id.present? && order.stripe_refund_id != @refund.id
      return if mismatched_payment_intent?(order)
      return if terminal_event_already_applied?(order)

      attributes = {
        stripe_refund_id: @refund.id,
        stripe_payment_intent_id: payment_intent_id.presence || order.stripe_payment_intent_id,
        refund_status: @refund.status
      }

      if @refund.status == "succeeded"
        attributes[:status] = :refunded
        attributes[:refunded_at] = order.refunded_at || Time.current
      end

      order.update!(attributes)
    end
  end

  private

  def find_order
    Order.find_by(stripe_refund_id: @refund.id) ||
      Order.find_by(id: @refund.metadata&.[]("order_id"))
  end

  def payment_intent_id
    value = @refund.payment_intent
    value.respond_to?(:id) ? value.id : value
  end

  def mismatched_payment_intent?(order)
    order.stripe_payment_intent_id.present? &&
      payment_intent_id.present? &&
      order.stripe_payment_intent_id != payment_intent_id
  end

  def terminal_event_already_applied?(order)
    order.refund_status.in?(TERMINAL_STATUSES) && order.refund_status != @refund.status
  end
end
