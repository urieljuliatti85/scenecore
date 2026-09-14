FactoryBot.define do
  factory :band do
    sequence(:name) { |n| "Band #{n}" }
    description { "A great band." }
    status { :pending }

    trait :approved do
      status { :approved }
    end

    trait :rejected do
      status { :rejected }
    end

    trait :suspended do
      status { :suspended }
    end
  end
end
