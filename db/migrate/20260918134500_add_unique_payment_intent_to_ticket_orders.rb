class AddUniquePaymentIntentToTicketOrders < ActiveRecord::Migration[8.1]
  def change
    add_index :ticket_orders, :stripe_payment_intent_id, unique: true
  end
end
