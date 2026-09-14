class AddSpotifyUrlToTracks < ActiveRecord::Migration[8.1]
  def change
    add_column :tracks, :spotify_url, :string
  end
end
