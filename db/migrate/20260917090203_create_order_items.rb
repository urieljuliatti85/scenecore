class CreateOrderItems < ActiveRecord::Migration[8.1]
  def change
    create_table :order_items do |t|
      t.references :order, null: false, foreign_key: true
      # Kept for traceability only (docs/database.md OrderItems) — never
      # used to re-derive price/name after the order is placed. Nullify
      # rather than restrict on delete: the snapshot columns carry the
      # order's history, so deleting a variant must not be blocked by,
      # nor destroy, a past order.
      t.references :product_variant, foreign_key: { on_delete: :nullify }
      t.string :product_name, null: false
      t.string :variant_name, null: false
      t.integer :unit_price_cents, null: false
      t.integer :quantity, null: false

      t.timestamps
    end

    add_check_constraint :order_items, "unit_price_cents >= 0", name: "order_items_unit_price_cents_check"
    add_check_constraint :order_items, "quantity > 0", name: "order_items_quantity_check"
  end
end
