FactoryBot.define do
  factory :comment do
    post
    user
    body { "Great song!" }
  end
end
