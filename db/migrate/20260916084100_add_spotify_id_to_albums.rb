class AddSpotifyIdToAlbums < ActiveRecord::Migration[8.1]
  def change
    # Nullable: albums imported before this column existed have no
    # Spotify id, and an album created without Spotify never will.
    add_column :albums, :spotify_id, :string
    add_index :albums, :spotify_id
  end
end
