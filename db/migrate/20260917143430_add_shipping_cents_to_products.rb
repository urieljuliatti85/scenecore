class AddShippingCentsToProducts < ActiveRecord::Migration[8.1]
  # Per-product shipping, set by the band. The platform-wide calculation
  # method (flat rate, zone/weight, carrier API) is still an open product
  # question — this is the manual figure a band enters until one is chosen,
  # and Order#shipping_cents stays provider-agnostic either way.
  def change
    add_column :products, :shipping_cents, :integer, null: false, default: 0
    add_check_constraint :products, "shipping_cents >= 0", name: "products_shipping_cents_check"
  end
end
