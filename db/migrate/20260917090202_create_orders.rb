class CreateOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :orders do |t|
      t.references :user, null: false, foreign_key: true
      t.references :band, null: false, foreign_key: true
      t.string :status, null: false, default: "pending"
      t.integer :subtotal_cents, null: false
      t.integer :shipping_cents, null: false, default: 0
      t.integer :total_cents, null: false
      t.integer :platform_fee_cents, null: false
      t.string :stripe_checkout_session_id

      t.timestamps
    end

    add_index :orders, :stripe_checkout_session_id, unique: true
    add_check_constraint :orders, "status IN ('pending', 'paid', 'processing', 'completed', 'cancelled', 'refunded')",
                          name: "orders_status_check"
    add_check_constraint :orders, "subtotal_cents >= 0 AND shipping_cents >= 0 AND total_cents >= 0 AND platform_fee_cents >= 0",
                          name: "orders_amounts_non_negative_check"
  end
end
