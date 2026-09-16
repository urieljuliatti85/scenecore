FactoryBot.define do
  factory :subscription do
    user
    band
    level { :fan }
    status { :pending }
    sequence(:stripe_customer_id) { |n| "cus_test#{n}" }

    trait :supporter do
      level { :supporter }
    end

    trait :core_member do
      level { :core_member }
    end

    trait :active do
      status { :active }
      sequence(:stripe_subscription_id) { |n| "sub_test#{n}" }
    end

    trait :past_due do
      status { :past_due }
    end

    trait :cancelled do
      status { :cancelled }
    end

    trait :expired do
      status { :expired }
    end
  end
end
