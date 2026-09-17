class CreatePlatformSettings < ActiveRecord::Migration[8.1]
  def change
    create_table :platform_settings do |t|
      t.integer :platform_fee_percentage, null: false, default: 0
      t.string :terms_of_service_url
      t.string :privacy_policy_url
      t.string :support_email
      t.string :notification_sender_email
      t.boolean :band_signups_enabled, null: false, default: true

      t.timestamps
    end

    add_check_constraint :platform_settings, "platform_fee_percentage BETWEEN 0 AND 100", name: "platform_settings_fee_range_check"
  end
end
