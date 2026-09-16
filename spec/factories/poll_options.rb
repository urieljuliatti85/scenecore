FactoryBot.define do
  factory :poll_option do
    poll
    sequence(:label) { |n| "Option #{n}" }
  end
end
