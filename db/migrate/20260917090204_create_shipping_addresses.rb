class CreateShippingAddresses < ActiveRecord::Migration[8.1]
  def change
    create_table :shipping_addresses do |t|
      t.references :order, null: false, foreign_key: true, index: { unique: true }
      t.string :recipient_name, null: false
      t.string :line1, null: false
      t.string :line2
      t.string :city, null: false
      t.string :state, null: false
      t.string :postal_code, null: false
      t.string :country, null: false

      t.timestamps
    end
  end
end
