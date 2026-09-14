class CreateBands < ActiveRecord::Migration[8.1]
  def change
    create_table :bands do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description
      t.string :status, null: false, default: "pending"

      t.timestamps
    end

    add_index :bands, :slug, unique: true
    add_index :bands, :status
  end
end
