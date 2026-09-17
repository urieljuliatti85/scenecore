FactoryBot.define do
  factory :core_session do
    band
    sequence(:title) { |n| "Core Session #{n}" }
    session_type { :qa }
    starts_at { 1.week.from_now }
    description { "A private session for Core Members." }
    status { :draft }

    trait :published do
      status { :published }
    end
  end
end
