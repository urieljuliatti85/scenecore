require "rails_helper"

RSpec.describe "Band Admin product variants", type: :request do
  let(:band) { create(:band) }
  let(:admin) { create(:user) }
  let(:product) { create(:product, band: band, name: "Tour Tee") }
  let!(:variant) do
    product.variants.create!(name: "M / Black", sku: "TEE-BLK-M", price_cents: 2500, stock_quantity: 12)
  end

  before do
    create(:band_membership, :administrator, band: band, user: admin)
    sign_in admin
  end

  describe "GET /bands/:band_id/products/:product_id/variants/:id/edit" do
    # The routes name this resource :variants while the class is
    # ProductVariant, so form_with cannot infer the path helper from the
    # model — it looked for band_product_product_variant_path and raised.
    it "renders the edit form" do
      get edit_band_product_variant_path(band, product, variant)

      expect(response).to have_http_status(:ok)
    end

    it "posts back to the variant's own path" do
      get edit_band_product_variant_path(band, product, variant)

      form = Nokogiri::HTML(response.body).css("form").find { |f| f.css("input[name^='product_variant']").any? }

      expect(form["action"]).to eq(band_product_variant_path(band, product, variant))
      expect(form.css("input[name='_method']").first["value"]).to eq("patch")
    end

    it "prefills the variant's current values" do
      get edit_band_product_variant_path(band, product, variant)

      doc = Nokogiri::HTML(response.body)

      expect(doc.css("input[name='product_variant[sku]']").first["value"]).to eq("TEE-BLK-M")
      expect(doc.css("input[name='product_variant[price_cents]']").first["value"]).to eq("2500")
    end
  end

  describe "GET /bands/:band_id/products/:product_id/variants/new" do
    it "renders the new form against the collection path" do
      get new_band_product_variant_path(band, product)

      expect(response).to have_http_status(:ok)

      form = Nokogiri::HTML(response.body).css("form").find { |f| f.css("input[name^='product_variant']").any? }

      expect(form["action"]).to eq(band_product_variants_path(band, product))
    end
  end

  describe "PATCH /bands/:band_id/products/:product_id/variants/:id" do
    it "updates the variant" do
      patch band_product_variant_path(band, product, variant), params: {
        product_variant: { name: "L / Black", sku: "TEE-BLK-L", price_cents: 3000, stock_quantity: 4 }
      }

      expect(response).to redirect_to(edit_band_product_path(band, product))
      expect(variant.reload.name).to eq("L / Black")
      expect(variant.price_cents).to eq(3000)
    end

    # Keeping the SKU is the ordinary case when only price or stock changes,
    # and the uniqueness validation must not fire against the record itself.
    it "accepts an unchanged SKU" do
      patch band_product_variant_path(band, product, variant), params: {
        product_variant: { name: "M / Black", sku: "TEE-BLK-M", price_cents: 2900, stock_quantity: 12 }
      }

      expect(response).to redirect_to(edit_band_product_path(band, product))
      expect(variant.reload.price_cents).to eq(2900)
    end

    it "re-renders with the error when the variant is invalid" do
      patch band_product_variant_path(band, product, variant), params: {
        product_variant: { name: "", sku: "TEE-BLK-M", price_cents: 2500, stock_quantity: 12 }
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("Name can&#39;t be blank")
    end

    it "rejects a SKU another variant already uses" do
      create(:product, band: band).variants.create!(
        name: "Other", sku: "TAKEN-SKU", price_cents: 1000, stock_quantity: 1
      )

      patch band_product_variant_path(band, product, variant), params: {
        product_variant: { name: "M / Black", sku: "TAKEN-SKU", price_cents: 2500, stock_quantity: 12 }
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(variant.reload.sku).to eq("TEE-BLK-M")
    end
  end

  describe "authorization" do
    it "does not let a non-administrator member edit a variant" do
      member = create(:user)
      create(:band_membership, band: band, user: member, role: :member)
      sign_in member

      get edit_band_product_variant_path(band, product, variant)

      expect(response).to have_http_status(:found)
    end

    it "does not let another band's administrator edit a variant" do
      other_admin = create(:user)
      create(:band_membership, :administrator, band: create(:band), user: other_admin)
      sign_in other_admin

      patch band_product_variant_path(band, product, variant), params: {
        product_variant: { name: "Hacked", sku: "TEE-BLK-M", price_cents: 1, stock_quantity: 0 }
      }

      expect(variant.reload.name).to eq("M / Black")
    end
  end
end
