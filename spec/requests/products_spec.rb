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
      expect(product.variants.first.sku).to eq("TEE-BLK-M")
      expect(response).to redirect_to(band_products_path(band))
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
