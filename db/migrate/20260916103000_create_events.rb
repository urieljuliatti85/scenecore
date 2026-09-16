class CreateEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :events do |t|
      t.references :band, null: false, foreign_key: true
      t.string :title, null: false
      t.string :location, null: false
      t.datetime :starts_at, null: false
      t.string :ticket_url
      t.text :description
      t.string :status, null: false, default: "draft"

      t.timestamps
    end

    add_index :events, [ :band_id, :status, :starts_at ]
    add_check_constraint :events, "status IN ('draft', 'published')", name: "events_status_check"
  end
end
