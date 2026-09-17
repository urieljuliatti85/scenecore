FactoryBot.define do
  factory :product do
    band
    sequence(:name) { |n| "Product #{n}" }
    description { "A great product." }
    status { :draft }

    trait :published do
      status { :published }
    end
  end
end
