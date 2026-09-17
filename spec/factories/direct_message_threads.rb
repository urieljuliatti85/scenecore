FactoryBot.define do
  factory :direct_message_thread do
    band
    user
    status { :open }

    trait :archived do
      status { :archived }
    end

    trait :blocked do
      status { :blocked }
    end
  end
end
