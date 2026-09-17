class AddBandcampEmbedUrlToAlbums < ActiveRecord::Migration[8.1]
  def change
    add_column :albums, :bandcamp_embed_url, :string
  end
end
