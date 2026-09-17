FactoryBot.define do
  factory :shipping_address do
    order
    recipient_name { "Jane Fan" }
    line1 { "123 Main St" }
    city { "Porto Alegre" }
    state { "RS" }
    postal_code { "90000-000" }
    country { "BR" }
  end
end
