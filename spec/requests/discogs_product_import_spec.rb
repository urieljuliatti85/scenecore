require "rails_helper"

RSpec.describe "Discogs product import", type: :request do
  let(:band) { create(:band) }
  let(:admin) { create(:user) }
  let(:client) { instance_double(DiscogsClient) }

  before do
    create(:band_membership, :administrator, band: band, user: admin)
    sign_in admin
    allow(DiscogsClient).to receive(:new).and_return(client)
  end

  it "searches Discogs through the Band Admin products endpoint" do
    result = DiscogsClient::ReleaseResult.new(
      discogs_release_id: 123,
      title: "Record Name",
      artist: "Band Name",
      year: 2026,
      format: "Vinyl",
      label: "Scene Records",
      catalog_number: "SC-001",
      country: "Brazil"
    )
    allow(client).to receive(:search_releases).with("Record Name").and_return([ result ])

    get band_products_path(band, format: :json), params: { q: "Record Name" }

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.first).to include(
      "discogs_release_id" => 123,
      "title" => "Record Name",
      "artist" => "Band Name"
    )
  end

  it "imports verified Discogs metadata while keeping commerce fields in the variant" do
    details = DiscogsClient::ReleaseDetails.new(
      discogs_release_id: 123,
      title: "Verified Record Name",
      artist: "Band Name",
      year: 2026,
      format: "Vinyl · LP",
      label: "Scene Records",
      catalog_number: "SC-001",
      barcode: "7891234567890",
      country: "Brazil",
      discogs_url: "https://www.discogs.com/release/123",
      metadata: { "country" => "Brazil", "genres" => [ "Rock" ] }
    )
    allow(client).to receive(:fetch_release).with("123").and_return(details)

    expect {
      post band_products_path(band), params: {
        discogs_release_id: "123",
        product: {
          name: "Tampered browser title",
          description: "Limited pressing",
          variants_attributes: {
            "0" => { name: "Default", sku: "VINYL-001", price_cents: 12000, stock_quantity: 10 }
          }
        }
      }
    }.to change(Product, :count).by(1).and change(ProductVariant, :count).by(1)

    product = band.products.last
    expect(product).to have_attributes(
      source: "discogs",
      discogs_release_id: 123,
      name: "Verified Record Name",
      artist_name: "Band Name",
      release_year: 2026,
      release_format: "Vinyl · LP",
      label_name: "Scene Records",
      catalog_number: "SC-001",
      barcode: "7891234567890",
      status: "draft"
    )
    expect(product.variants.first).to have_attributes(
      sku: "VINYL-001",
      price_cents: 12000,
      stock_quantity: 10
    )
    expect(product.discogs_metadata).to include("country" => "Brazil")
    expect(product.discogs_synced_at).to be_present
  end

  it "does not allow a plain band member to search Discogs for product import" do
    member = create(:user)
    create(:band_membership, band: band, user: member)
    sign_in member

    expect(client).not_to receive(:search_releases)

    get band_products_path(band, format: :json), params: { q: "Record Name" }

    expect(response).to redirect_to(root_path)
  end

  it "shows a service error instead of creating a product when Discogs is unavailable" do
    allow(client).to receive(:fetch_release).and_raise(DiscogsClient::Error, "unavailable")

    expect {
      post band_products_path(band), params: {
        discogs_release_id: "123",
        product: {
          name: "Record Name",
          variants_attributes: {
            "0" => { name: "Default", sku: "VINYL-ERR", price_cents: 12000, stock_quantity: 1 }
          }
        }
      }
    }.not_to change(Product, :count)

    expect(response).to have_http_status(:bad_gateway)
    expect(response.body).to include("Could not import this release from Discogs")
  end
end
