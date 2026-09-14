FactoryBot.define do
  factory :category do
    sequence(:name) { |n| "Category #{n}" }

    trait :with_parent do
      parent factory: :category
    end
  end
end
