FactoryBot.define do
  factory :band_admin_request do
    user
    band

    trait :approved do
      status { :approved }
    end

    trait :rejected do
      status { :rejected }
    end

    trait :revoked do
      status { :revoked }
    end
  end
end
