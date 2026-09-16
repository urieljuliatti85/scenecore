class CreateSubscriptions < ActiveRecord::Migration[8.1]
  def change
    create_table :subscriptions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :band, null: false, foreign_key: true
      t.string :level, null: false
      t.string :status, null: false, default: "pending"
      t.string :stripe_customer_id, null: false
      t.string :stripe_checkout_session_id
      t.string :stripe_subscription_id

      t.timestamps
    end

    add_index :subscriptions, [ :user_id, :band_id ], unique: true
    add_index :subscriptions, :stripe_checkout_session_id, unique: true
    add_index :subscriptions, :stripe_subscription_id, unique: true

    add_check_constraint :subscriptions, "level IN ('fan', 'supporter', 'core_member')", name: "subscriptions_level_check"
    add_check_constraint :subscriptions, "status IN ('pending', 'active', 'past_due', 'cancelled', 'expired')", name: "subscriptions_status_check"
  end
end
