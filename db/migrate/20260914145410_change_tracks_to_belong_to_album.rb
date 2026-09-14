class ChangeTracksToBelongToAlbum < ActiveRecord::Migration[8.1]
  def change
    remove_reference :tracks, :band, foreign_key: true, index: true
    add_reference :tracks, :album, null: false, foreign_key: true
    add_column :tracks, :track_number, :integer, null: false
    add_index :tracks, [ :album_id, :status ]
  end
end
