FactoryBot.define do
  factory :shipping_zone do
    band
    sequence(:name) { |n| "Destination #{n}" }
    shipping_cents { 1_500 }

    # Countries are passed as codes because that is how the form and
    # controller work with them; the join records are built here.
    transient do
      country_codes { [ "BR" ] }
    end

    after(:build) do |zone, evaluator|
      evaluator.country_codes.each do |code|
        zone.zone_countries.build(band: zone.band, country_code: code)
      end
    end
  end

  factory :product_shipping_rate do
    product
    shipping_zone { create(:shipping_zone, band: product.band) }
    shipping_cents { 500 }
  end
end
