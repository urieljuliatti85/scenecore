FactoryBot.define do
  factory :event do
    band
    sequence(:title) { |n| "Show #{n}" }
    location { "Centro Cultural, São Paulo" }
    starts_at { 1.week.from_now }
    ticket_url { "https://example.com/tickets" }
    description { "A live show." }
    status { :draft }

    trait :published do
      status { :published }
    end

    trait :past do
      starts_at { 1.week.ago }
    end
  end
end
