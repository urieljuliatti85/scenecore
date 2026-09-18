class AddRefundTrackingToOrders < ActiveRecord::Migration[8.1]
  def change
    add_column :orders, :stripe_payment_intent_id, :string
    add_column :orders, :stripe_refund_id, :string
    add_column :orders, :refund_status, :string
    add_column :orders, :refunded_at, :datetime

    add_index :orders, :stripe_payment_intent_id, unique: true
    add_index :orders, :stripe_refund_id, unique: true
    add_check_constraint :orders,
                         "refund_status IS NULL OR refund_status IN ('pending', 'requires_action', 'succeeded', 'failed', 'canceled')",
                         name: "orders_refund_status_check"
  end
end
