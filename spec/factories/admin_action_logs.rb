FactoryBot.define do
  factory :admin_action_log do
    actor factory: :user
    action { "approve_band" }
    subject factory: :band
  end
end
