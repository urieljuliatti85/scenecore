class CreateMerchDiscounts < ActiveRecord::Migration[8.1]
  def change
    create_table :merch_discounts do |t|
      t.references :band, null: false, foreign_key: true
      t.string :level, null: false
      t.integer :percentage, null: false, default: 0

      t.timestamps
    end

    add_index :merch_discounts, [ :band_id, :level ], unique: true
    add_check_constraint :merch_discounts, "level IN ('fan', 'supporter', 'core_member')", name: "merch_discounts_level_check"
    add_check_constraint :merch_discounts, "percentage BETWEEN 0 AND 100", name: "merch_discounts_percentage_range_check"
  end
end
