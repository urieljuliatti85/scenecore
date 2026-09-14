class AddSpotifyCoverUrlToAlbums < ActiveRecord::Migration[8.1]
  def change
    add_column :albums, :spotify_cover_url, :string
  end
end
