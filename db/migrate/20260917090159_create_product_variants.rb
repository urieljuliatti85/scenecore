class CreateProductVariants < ActiveRecord::Migration[8.1]
  def change
    create_table :product_variants do |t|
      t.references :product, null: false, foreign_key: true
      t.string :sku, null: false
      t.string :name, null: false
      t.integer :price_cents, null: false
      t.integer :stock_quantity, null: false, default: 0

      t.timestamps
    end

    add_index :product_variants, :sku, unique: true
    add_check_constraint :product_variants, "price_cents >= 0", name: "product_variants_price_cents_check"
    add_check_constraint :product_variants, "stock_quantity >= 0", name: "product_variants_stock_quantity_check"
  end
end
