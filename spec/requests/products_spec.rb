require "rails_helper"

RSpec.describe "Band Admin products", type: :request do
  describe "product management" do
    it "lets a band administrator create a product with its first variant" do
      band = create(:band)
      admin = create(:user)
      create(:band_membership, :administrator, band: band, user: admin)
      sign_in admin

      expect {
        post band_products_path(band), params: {
          product: {
            name: "Tour Tee",
            description: "Black cotton shirt",
            variants_attributes: {
              "0" => { name: "M / Black", sku: "TEE-BLK-M", price_cents: 2500, stock_quantity: 12 }
            }
          }
        }
      }.to change(Product, :count).by(1).and change(ProductVariant, :count).by(1)

      product = band.products.last
      expect(product).to be_draft
      expect(product).to be_manual
      expect(product.variants.first.sku).to eq("TEE-BLK-M")
      expect(response).to redirect_to(band_products_path(band))
    end

    it "imports trusted release metadata from Discogs while keeping commerce fields local" do
      band = create(:band)
      admin = create(:user)
      create(:band_membership, :administrator, band: band, user: admin)
      sign_in admin

      details = DiscogsClient::ReleaseDetails.new(
        discogs_release_id: 123,
        title: "Distant Place",
        artist: "Lifelöck",
        year: 2026,
        format: "Vinyl · LP",
        label: "Scene Records",
        catalog_number: "SC-001",
        barcode: "7891234567890",
        country: "Brazil",
        discogs_url: "https://www.discogs.com/release/123",
        metadata: { "genres" => [ "Rock" ], "styles" => [ "Crust" ] }
      )
      client = instance_double(DiscogsClient, fetch_release: details)
      allow(DiscogsClient).to receive(:new).and_return(client)

      expect {
        post band_products_path(band), params: {
          discogs_release_id: "123",
          product: {
            name: "Tampered browser title",
            description: "Limited pressing",
            variants_attributes: {
              "0" => { name: "Default", sku: "LIFE-DP-LP", price_cents: 12000, stock_quantity: 20 }
            }
          }
        }
      }.to change(Product, :count).by(1).and change(ProductVariant, :count).by(1)

      product = band.products.last
      expect(product).to have_attributes(
        source: "discogs",
        discogs_release_id: 123,
        name: "Distant Place",
        artist_name: "Lifelöck",
        release_year: 2026,
        release_format: "Vinyl · LP",
        label_name: "Scene Records",
        catalog_number: "SC-001",
        barcode: "7891234567890"
      )
      expect(product.discogs_metadata).to include("styles" => [ "Crust" ])
      expect(product.discogs_synced_at).to be_present
      expect(product.variants.first).to have_attributes(sku: "LIFE-DP-LP", price_cents: 12000, stock_quantity: 20)
    end

    # The cover is what makes the store look like a record shop
    # (docs/product.md, Store, decided 2026-09-17).
    it "attaches the release cover from Discogs" do
      band = create(:band)
      admin = create(:user)
      create(:band_membership, :administrator, band: band, user: admin)
      sign_in admin

      details = DiscogsClient::ReleaseDetails.new(
        discogs_release_id: 123, title: "Distant Place",
        image_url: "https://img.example.com/front.jpg",
        metadata: {}
      )
      allow(DiscogsClient).to receive(:new).and_return(instance_double(DiscogsClient, fetch_release: details))

      fetched = RemoteImageFetcher::Result.new(
        io: StringIO.new("image-bytes"), filename: "front.jpg", content_type: "image/jpeg"
      )
      allow_any_instance_of(RemoteImageFetcher).to receive(:call)
        .with("https://img.example.com/front.jpg").and_return(fetched)

      post band_products_path(band), params: {
        discogs_release_id: "123",
        product: { variants_attributes: {
          "0" => { name: "Default", sku: "COVER-1", price_cents: 12000, stock_quantity: 1 }
        } }
      }

      expect(band.products.last.image).to be_attached
    end

    # A cover that cannot be downloaded must not cost the band the import:
    # the metadata is already correct and a photo can be uploaded by hand.
    it "still imports the product when the cover cannot be fetched" do
      band = create(:band)
      admin = create(:user)
      create(:band_membership, :administrator, band: band, user: admin)
      sign_in admin

      details = DiscogsClient::ReleaseDetails.new(
        discogs_release_id: 123, title: "Distant Place",
        image_url: "https://img.example.com/front.jpg",
        metadata: {}
      )
      allow(DiscogsClient).to receive(:new).and_return(instance_double(DiscogsClient, fetch_release: details))
      allow_any_instance_of(RemoteImageFetcher).to receive(:call)
        .and_raise(RemoteImageFetcher::Error, "too large")

      expect {
        post band_products_path(band), params: {
          discogs_release_id: "123",
          product: { variants_attributes: {
            "0" => { name: "Default", sku: "COVER-2", price_cents: 12000, stock_quantity: 1 }
          } }
        }
      }.to change(Product, :count).by(1)

      product = band.products.last
      expect(product.name).to eq("Distant Place")
      expect(product.image).not_to be_attached
    end

    it "lets a band administrator search Discogs releases" do
      band = create(:band)
      admin = create(:user)
      create(:band_membership, :administrator, band: band, user: admin)
      sign_in admin

      result = DiscogsClient::ReleaseResult.new(
        discogs_release_id: 123,
        title: "Distant Place",
        artist: "Lifelöck",
        year: 2026,
        format: "Vinyl",
        label: "Scene Records",
        catalog_number: "SC-001",
        country: "Brazil"
      )
      client = instance_double(DiscogsClient, search_releases: [ result ])
      allow(DiscogsClient).to receive(:new).and_return(client)

      get band_products_path(band, format: :json), params: { q: "Distant Place" }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.first).to include(
        "discogs_release_id" => 123,
        "title" => "Distant Place",
        "artist" => "Lifelöck"
      )
    end

    it "does not let a plain band member search Discogs" do
      band = create(:band)
      member = create(:user)
      create(:band_membership, band: band, user: member)
      sign_in member

      get band_products_path(band, format: :json), params: { q: "Distant Place" }

      expect(response).to redirect_to(root_path)
    end

    it "requires the first variant when creating a product" do
      band = create(:band)
      admin = create(:user)
      create(:band_membership, :administrator, band: band, user: admin)
      sign_in admin

      expect {
        post band_products_path(band), params: { product: { name: "Incomplete product" } }
      }.not_to change(Product, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "does not let a plain band member manage products" do
      band = create(:band)
      member = create(:user)
      create(:band_membership, band: band, user: member)
      sign_in member

      expect {
        post band_products_path(band), params: {
          product: {
            name: "Forbidden",
            variants_attributes: {
              "0" => { name: "Default", sku: "NOPE-1", price_cents: 1000, stock_quantity: 1 }
            }
          }
        }
      }.not_to change(Product, :count)

      expect(response).to redirect_to(root_path)
    end

    it "prevents an administrator from managing another band's product" do
      admin = create(:user)
      own_band = create(:band)
      create(:band_membership, :administrator, band: own_band, user: admin)
      other_band = create(:band)
      product = create(:product, band: other_band)
      sign_in admin

      patch band_product_path(other_band, product), params: { product: { name: "Hijacked" } }

      expect(product.reload.name).not_to eq("Hijacked")
      expect(response).to redirect_to(root_path)
    end

    it "publishes a product that has a variant" do
      band = create(:band)
      admin = create(:user)
      create(:band_membership, :administrator, band: band, user: admin)
      product = create(:product, band: band)
      create(:product_variant, product: product)
      sign_in admin

      patch publish_band_product_path(band, product)

      expect(product.reload).to be_published
    end

    it "refuses to publish a product without a variant" do
      band = create(:band)
      admin = create(:user)
      create(:band_membership, :administrator, band: band, user: admin)
      product = create(:product, band: band)
      sign_in admin

      patch publish_band_product_path(band, product)

      expect(product.reload).to be_draft
      expect(response).to redirect_to(band_products_path(band))
    end
  end

  describe "variant management" do
    it "lets a band administrator add a variant" do
      band = create(:band)
      admin = create(:user)
      create(:band_membership, :administrator, band: band, user: admin)
      product = create(:product, band: band)
      sign_in admin

      expect {
        post band_product_variants_path(band, product), params: {
          product_variant: { name: "L / Black", sku: "TEE-BLK-L", price_cents: 2500, stock_quantity: 8 }
        }
      }.to change(product.variants, :count).by(1)
    end

    it "does not allow deleting the product's last variant" do
      band = create(:band)
      admin = create(:user)
      create(:band_membership, :administrator, band: band, user: admin)
      product = create(:product, band: band)
      variant = create(:product_variant, product: product)
      sign_in admin

      expect {
        delete band_product_variant_path(band, product, variant)
      }.not_to change(ProductVariant, :count)

      expect(response).to redirect_to(edit_band_product_path(band, product))
    end
  end
end
