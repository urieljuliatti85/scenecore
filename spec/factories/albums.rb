FactoryBot.define do
  factory :album do
    band
    sequence(:title) { |n| "Album #{n}" }
    status { :draft }

    trait :published do
      status { :published }
    end
  end
end
