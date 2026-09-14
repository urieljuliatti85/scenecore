class AddSocialLinksToBands < ActiveRecord::Migration[8.1]
  def change
    add_column :bands, :spotify_url, :string
    add_column :bands, :youtube_url, :string
    add_column :bands, :instagram_url, :string
    add_column :bands, :website_url, :string
  end
end
