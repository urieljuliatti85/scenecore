FactoryBot.define do
  factory :track do
    band
    sequence(:title) { |n| "Track #{n}" }
    status { :draft }

    trait :published do
      status { :published }
    end
  end
end
