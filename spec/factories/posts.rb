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

    trait :subscribers_only do
      visibility { :subscribers }
    end
  end
end
