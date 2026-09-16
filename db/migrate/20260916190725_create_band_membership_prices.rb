class CreateBandMembershipPrices < ActiveRecord::Migration[8.1]
  def change
    create_table :band_membership_prices do |t|
      t.references :band, null: false, foreign_key: true
      t.string :level, null: false
      t.string :stripe_product_id, null: false
      t.string :stripe_price_id, null: false

      t.timestamps
    end

    add_index :band_membership_prices, [ :band_id, :level ], unique: true

    add_check_constraint :band_membership_prices, "level IN ('fan', 'supporter', 'core_member')", name: "band_membership_prices_level_check"
  end
end
