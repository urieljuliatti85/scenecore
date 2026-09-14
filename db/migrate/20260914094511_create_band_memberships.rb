class CreateBandMemberships < ActiveRecord::Migration[8.1]
  def change
    create_table :band_memberships do |t|
      t.references :user, null: false, foreign_key: true
      t.references :band, null: false, foreign_key: true
      t.string :role, null: false, default: "member"

      t.timestamps
    end

    add_index :band_memberships, [ :user_id, :band_id ], unique: true
    add_index :band_memberships, [ :band_id, :role ]
  end
end
