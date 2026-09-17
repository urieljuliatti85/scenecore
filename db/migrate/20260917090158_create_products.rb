class CreateProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :products do |t|
      t.references :band, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.string :status, null: false, default: "draft"

      t.timestamps
    end

    add_check_constraint :products, "status IN ('draft', 'published')", name: "products_status_check"
  end
end
