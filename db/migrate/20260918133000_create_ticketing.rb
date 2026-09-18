class CreateTicketing < ActiveRecord::Migration[8.1]
  def change
    create_table :ticket_batches do |t|
      t.references :event, null: false, foreign_key: true
      t.string :name, null: false
      t.integer :price_cents, null: false
      t.integer :quantity_total, null: false
      t.datetime :sales_start_at
      t.datetime :sales_end_at

      t.timestamps
    end

    add_check_constraint :ticket_batches, "price_cents >= 0", name: "ticket_batches_price_non_negative"
    add_check_constraint :ticket_batches, "quantity_total > 0", name: "ticket_batches_quantity_positive"
    add_check_constraint :ticket_batches,
                         "sales_end_at IS NULL OR sales_start_at IS NULL OR sales_end_at > sales_start_at",
                         name: "ticket_batches_sales_window_valid"

    create_table :ticket_orders do |t|
      t.references :ticket_batch, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :quantity, null: false
      t.integer :unit_price_cents, null: false
      t.integer :total_cents, null: false
      t.integer :platform_fee_cents, null: false
      t.string :status, null: false, default: "pending"
      t.string :stripe_checkout_session_id
      t.string :stripe_payment_intent_id
      t.datetime :expires_at, null: false
      t.datetime :paid_at

      t.timestamps
    end

    add_index :ticket_orders, :stripe_checkout_session_id, unique: true
    add_index :ticket_orders, [ :ticket_batch_id, :status, :expires_at ],
              name: "index_ticket_orders_on_batch_status_expiry"
    add_check_constraint :ticket_orders, "quantity > 0", name: "ticket_orders_quantity_positive"
    add_check_constraint :ticket_orders,
                         "unit_price_cents >= 0 AND total_cents >= 0 AND platform_fee_cents >= 0",
                         name: "ticket_orders_amounts_non_negative"
    add_check_constraint :ticket_orders,
                         "status IN ('pending', 'paid', 'expired')",
                         name: "ticket_orders_status_check"

    create_table :tickets do |t|
      t.references :ticket_order, null: false, foreign_key: true
      t.references :event, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :checked_in_by, foreign_key: { to_table: :users }
      t.string :public_token, null: false
      t.datetime :used_at

      t.timestamps
    end

    add_index :tickets, :public_token, unique: true
    add_index :tickets, [ :event_id, :used_at ]
    add_check_constraint :tickets,
                         "(used_at IS NULL AND checked_in_by_id IS NULL) OR (used_at IS NOT NULL AND checked_in_by_id IS NOT NULL)",
                         name: "tickets_check_in_pair"
  end
end
