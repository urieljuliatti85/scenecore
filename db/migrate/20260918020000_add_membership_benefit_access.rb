class AddMembershipBenefitAccess < ActiveRecord::Migration[8.1]
  def change
    add_column :products, :early_access_level, :string
    add_column :products, :early_access_until, :datetime
    add_check_constraint :products,
      "early_access_level IS NULL OR early_access_level IN ('fan', 'supporter', 'core_member')",
      name: "products_early_access_level_check"

    add_column :core_sessions, :audience_level, :string, default: "core_member", null: false
    add_column :core_sessions, :access_url, :string
    add_check_constraint :core_sessions,
      "audience_level IN ('supporter', 'core_member')",
      name: "core_sessions_audience_level_check"
  end
end
