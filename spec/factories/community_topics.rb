FactoryBot.define do
  factory :community_topic do
    band
    user
    sequence(:title) { |n| "Community topic #{n}" }
    body { "A conversation for the band community." }
  end
end
