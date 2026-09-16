FactoryBot.define do
  factory :rating do
    user
    album
    score { 5 }
  end
end
