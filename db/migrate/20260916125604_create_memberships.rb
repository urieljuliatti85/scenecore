class CreateMemberships < ActiveRecord::Migration[8.1]
  def change
    create_table :memberships do |t|
      t.references :user, null: false, foreign_key: true
      t.references :band, null: false, foreign_key: true
      t.string :level, null: false, default: "fan"
      t.string :status, null: false, default: "active"

      t.timestamps
    end

    add_index :memberships, [ :user_id, :band_id ], unique: true
    add_index :memberships, [ :band_id, :level ]
    add_index :memberships, [ :band_id, :status ]

    add_check_constraint :memberships, "level IN ('fan', 'supporter', 'core_member')", name: "memberships_level_check"
    add_check_constraint :memberships, "status IN ('active', 'paused', 'cancelled', 'expired')", name: "memberships_status_check"
  end
end
