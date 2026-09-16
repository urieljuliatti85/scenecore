class AddBandcampUrlToBands < ActiveRecord::Migration[8.1]
  def change
    add_column :bands, :bandcamp_url, :string
  end
end
