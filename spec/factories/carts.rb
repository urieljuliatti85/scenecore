FactoryBot.define do
  factory :cart do
    user
    band
    status { :active }

    trait :converted do
      status { :converted }
    end

    trait :abandoned do
      status { :abandoned }
    end
  end
end
