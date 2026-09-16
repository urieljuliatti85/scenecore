FactoryBot.define do
  factory :poll do
    band
    sequence(:question) { |n| "Question #{n}?" }
    status { :draft }
    visibility { :public }
    allow_multiple_choices { false }
    allow_vote_change { false }

    transient do
      options_count { 2 }
    end

    after(:build) do |poll, evaluator|
      if poll.poll_options.empty?
        evaluator.options_count.times { |n| poll.poll_options.build(label: "Option #{n + 1}") }
      end
    end

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
