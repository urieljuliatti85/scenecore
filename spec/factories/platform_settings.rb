FactoryBot.define do
  factory :platform_setting do
    membership_fee_percentage { 15 }
    store_fee_percentage { 10 }
    band_signups_enabled { true }
  end
end
