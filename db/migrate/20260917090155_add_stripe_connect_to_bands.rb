class AddStripeConnectToBands < ActiveRecord::Migration[8.1]
  def change
    add_column :bands, :stripe_connect_account_id, :string
    add_column :bands, :stripe_connect_status, :string, null: false, default: "not_started"

    add_index :bands, :stripe_connect_account_id, unique: true
    add_check_constraint :bands, "stripe_connect_status IN ('not_started', 'onboarding', 'active', 'restricted')",
                          name: "bands_stripe_connect_status_check"
  end
end
