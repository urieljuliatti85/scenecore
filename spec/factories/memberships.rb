FactoryBot.define do
  factory :membership do
    user
    band
    level { :fan }
    status { :active }

    trait :supporter do
      level { :supporter }
    end

    trait :core_member do
      level { :core_member }
    end

    trait :paused do
      status { :paused }
    end

    trait :cancelled do
      status { :cancelled }
    end

    trait :expired do
      status { :expired }
    end
  end
end
