class TicketOrderFulfiller
  def self.call(order, payment_intent_id: nil)
    order.with_lock do
      return unless order.pending?

      order.quantity.times do
        order.tickets.create!(event: order.event, user: order.user)
      end

      order.update!(
        status: :paid,
        paid_at: Time.current,
        stripe_payment_intent_id: payment_intent_id
      )
    end
  end
end
