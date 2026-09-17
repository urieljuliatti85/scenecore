class CreateCarts < ActiveRecord::Migration[8.1]
  def change
    create_table :carts do |t|
      t.references :user, null: false, foreign_key: true
      t.references :band, null: false, foreign_key: true
      t.string :status, null: false, default: "active"

      t.timestamps
    end

    add_check_constraint :carts, "status IN ('active', 'converted', 'abandoned')", name: "carts_status_check"

    # At most one active cart per user, platform-wide (docs/database.md
    # Carts) — a partial unique index, not a model validation, since two
    # concurrent requests could otherwise both pass a Ruby-level check
    # before either commits.
    add_index :carts, :user_id, unique: true, where: "status = 'active'", name: "index_carts_on_user_id_when_active"
  end
end
