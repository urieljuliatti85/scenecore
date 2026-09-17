class AddShippingRatesToProducts < ActiveRecord::Migration[8.1]
  def change
    # Per-product override of the band's zone rate. Nullable on purpose:
    # NULL means "use the zone's rate", which is a different statement from
    # a rate of 0 (free shipping for this item).
    create_table :product_shipping_rates do |t|
      t.references :product, null: false, foreign_key: true
      t.references :shipping_zone, null: false, foreign_key: true
      t.integer :shipping_cents, null: false

      t.timestamps
    end

    add_index :product_shipping_rates, [ :product_id, :shipping_zone_id ], unique: true
    add_check_constraint :product_shipping_rates,
                         "shipping_cents >= 0",
                         name: "product_shipping_rates_shipping_cents_non_negative"
  end
end
