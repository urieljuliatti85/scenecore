FactoryBot.define do
  factory :report do
    reporter factory: :user
    association :reportable, factory: :post
    reason { "This looks like spam." }

    trait :resolved do
      status { :resolved }
    end

    trait :dismissed do
      status { :dismissed }
    end
  end
end
