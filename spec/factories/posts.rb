FactoryBot.define do
  factory :post do
    band
    sequence(:title) { |n| "Post #{n}" }
    body { "Some announcement." }
    status { :draft }
    visibility { :public }

    trait :published do
      status { :published }
    end

    trait :followers_only do
      visibility { :followers }
    end

    trait :fan_only do
      visibility { :fan }
    end

    trait :supporter_only do
      visibility { :supporter }
    end

    trait :core_member_only do
      visibility { :core_member }
    end
  end
end
