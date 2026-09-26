FactoryBot.define do
  factory :community_reply do
    community_topic
    user
    body { "A thoughtful community reply." }
  end
end
