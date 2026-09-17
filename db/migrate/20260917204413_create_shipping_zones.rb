class CreateShippingZones < ActiveRecord::Migration[8.1]
  def change
    create_table :shipping_zones do |t|
      t.references :band, null: false, foreign_key: true
      t.string :name, null: false
      t.integer :shipping_cents, null: false, default: 0
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :shipping_zones, [ :band_id, :name ], unique: true
    add_check_constraint :shipping_zones, "shipping_cents >= 0", name: "shipping_zones_shipping_cents_non_negative"

    # A destination is a country, stored as the same ISO-3166-1 alpha-2 code
    # that bands.country_code uses, so the buyer's country matches a zone by
    # equality rather than by parsing free text. Unique platform-wide per
    # band: two zones of the same band must never both claim a country, or
    # the rate for that destination would be ambiguous.
    create_table :shipping_zone_countries do |t|
      t.references :shipping_zone, null: false, foreign_key: true
      t.references :band, null: false, foreign_key: true
      t.string :country_code, null: false

      t.timestamps
    end

    add_index :shipping_zone_countries, [ :band_id, :country_code ], unique: true
    add_check_constraint :shipping_zone_countries,
                         "country_code ~ '^[A-Z]{2}$'",
                         name: "shipping_zone_countries_country_code_iso"
  end
end
