class AddCountryCodeToBands < ActiveRecord::Migration[8.1]
  def change
    add_column :bands, :country_code, :string, null: false, default: "BR"
    add_check_constraint :bands, "country_code ~ '^[A-Z]{2}$'", name: "bands_country_code_check"
  end
end
