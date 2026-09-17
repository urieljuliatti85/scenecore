class AddDiscogsMetadataToProducts < ActiveRecord::Migration[8.1]
  def change
    add_column :products, :source, :string, null: false, default: "manual"
    add_column :products, :discogs_release_id, :bigint
    add_column :products, :artist_name, :string
    add_column :products, :release_year, :integer
    add_column :products, :release_format, :string
    add_column :products, :label_name, :string
    add_column :products, :catalog_number, :string
    add_column :products, :barcode, :string
    add_column :products, :discogs_metadata, :jsonb, null: false, default: {}
    add_column :products, :discogs_synced_at, :datetime

    add_index :products, [ :band_id, :discogs_release_id ],
              unique: true,
              where: "discogs_release_id IS NOT NULL",
              name: "index_products_on_band_and_discogs_release"

    add_check_constraint :products,
                         "source IN ('manual', 'discogs')",
                         name: "products_source_check"
  end
end
