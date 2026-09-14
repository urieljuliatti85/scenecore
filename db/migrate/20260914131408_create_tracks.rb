class CreateTracks < ActiveRecord::Migration[8.1]
  def change
    create_table :tracks do |t|
      t.references :band, null: false, foreign_key: true
      t.string :title, null: false
      t.string :status, null: false, default: "draft"

      t.timestamps
    end

    add_index :tracks, [ :band_id, :status ]
  end
end
