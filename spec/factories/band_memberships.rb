FactoryBot.define do
  factory :band_membership do
    user
    band
    role { :member }

    trait :administrator do
      role { :administrator }
    end
  end
end
