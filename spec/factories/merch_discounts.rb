FactoryBot.define do
  factory :merch_discount do
    band
    level { :fan }
    percentage { 0 }
  end
end
