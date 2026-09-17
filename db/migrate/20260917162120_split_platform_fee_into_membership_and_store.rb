class SplitPlatformFeeIntoMembershipAndStore < ActiveRecord::Migration[8.1]
  # One percentage could not express two rates: memberships carry 15%
  # (ADR-008) and the Store 10% (ADR-007). The single field held neither —
  # it defaulted to 0 and nothing read it, while the real figures lived in
  # constants.
  #
  # The defaults are the ADR rates rather than 0, so an untouched install
  # charges what the documents say.
  def up
    add_column :platform_settings, :membership_fee_percentage, :integer, null: false, default: 15
    add_column :platform_settings, :store_fee_percentage, :integer, null: false, default: 10

    add_check_constraint :platform_settings,
      "membership_fee_percentage >= 0 AND membership_fee_percentage <= 100",
      name: "platform_settings_membership_fee_range_check"
    add_check_constraint :platform_settings,
      "store_fee_percentage >= 0 AND store_fee_percentage <= 100",
      name: "platform_settings_store_fee_range_check"

    remove_check_constraint :platform_settings, name: "platform_settings_fee_range_check"
    remove_column :platform_settings, :platform_fee_percentage
  end

  def down
    add_column :platform_settings, :platform_fee_percentage, :integer, null: false, default: 0
    add_check_constraint :platform_settings,
      "platform_fee_percentage >= 0 AND platform_fee_percentage <= 100",
      name: "platform_settings_fee_range_check"

    remove_column :platform_settings, :membership_fee_percentage
    remove_column :platform_settings, :store_fee_percentage
  end
end
