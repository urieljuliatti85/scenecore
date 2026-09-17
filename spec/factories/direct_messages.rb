FactoryBot.define do
  factory :direct_message do
    direct_message_thread
    user
    sent_by_band { false }
    body { "Hello!" }
  end
end
