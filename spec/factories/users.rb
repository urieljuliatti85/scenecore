FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password123" }
    name { "Test User" }
    platform_admin { false }

    trait :platform_admin do
      platform_admin { true }
    end
  end
end
