require "rails_helper"

RSpec.describe "Public band products", type: :request do
  it "shows published products and their variant price without authentication" do
    band = create(:band, :approved)
    product = create(:product, :published, band: band, name: "Distant Place LP", description: "Limited black vinyl")
    create(:product_variant, product: product, name: "Black vinyl", price_cents: 12_000, stock_quantity: 8)

    get public_band_path(band.slug)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Merch")
    expect(response.body).to include("Distant Place LP")
    expect(response.body).to include("Limited black vinyl")
    expect(response.body).to include("Black vinyl")
    expect(response.body).to include("$120.00")
    expect(response.body).to include("In stock")
    expect(response.body).to include("#merch")
  end

  it "does not expose draft products" do
    band = create(:band, :approved)
    published = create(:product, :published, band: band, name: "Public LP")
    draft = create(:product, band: band, name: "Secret LP")
    create(:product_variant, product: published)
    create(:product_variant, product: draft)

    get public_band_path(band.slug)

    expect(response.body).to include("Public LP")
    expect(response.body).not_to include("Secret LP")
  end

  it "marks a product sold out when every variant has zero stock" do
    band = create(:band, :approved)
    product = create(:product, :published, band: band, name: "Sold Out Tee")
    create(:product_variant, :sold_out, product: product, name: "M")
    create(:product_variant, :sold_out, product: product, name: "L")

    get public_band_path(band.slug)

    expect(response.body).to include("Sold Out Tee")
    expect(response.body).to include("Sold out")
  end

  it "shows a locked priority product to a Fan without exposing its image or purchase control" do
    band = create(:band, :approved)
    product = create(:product, :published, band: band, name: "Core Vinyl", early_access_level: :core_member, early_access_until: 1.day.from_now)
    create(:product_variant, product: product, price_cents: 12_000, stock_quantity: 8)
    fan = create(:user)
    create(:membership, band: band, user: fan, level: :fan)
    sign_in fan

    get public_band_path(band.slug)

    expect(response.body).to include("Core Vinyl")
    expect(response.body).to include("Available first to Core member")
    expect(response.body).not_to include("Add to cart")
  end
end
