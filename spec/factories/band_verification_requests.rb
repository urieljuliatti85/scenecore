FactoryBot.define do
  factory :band_verification_request do
    band
    sequence(:email) { |n| "official#{n}@band.example" }

    trait :email_sent do
      status { :email_sent }
    end

    trait :verified do
      status { :verified }
    end

    trait :rejected do
      status { :rejected }
    end
  end
end
