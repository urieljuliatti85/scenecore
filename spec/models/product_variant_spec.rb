require "rails_helper"

RSpec.describe ProductVariant do
  describe "validations" do
    it "requires a unique sku" do
      create(:product_variant, sku: "SKU-DUP")
      duplicate = build(:product_variant, sku: "SKU-DUP")

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:sku]).to be_present
    end

    it "rejects a negative price" do
      expect(build(:product_variant, price_cents: -1)).not_to be_valid
    end

    it "rejects negative stock" do
      expect(build(:product_variant, stock_quantity: -1)).not_to be_valid
    end
  end

  describe "#sold_out?" do
    it "is true only when no stock remains" do
      expect(build(:product_variant, stock_quantity: 0)).to be_sold_out
      expect(build(:product_variant, stock_quantity: 1)).not_to be_sold_out
    end
  end

  describe "destroying" do
    it "does not allow deleting a product's last variant" do
      variant = create(:product_variant)

      expect { variant.destroy }.not_to change(described_class, :count)
      expect(variant.errors[:base]).to include("A product must keep at least one variant")
    end

    it "allows deleting a variant when the product has another one" do
      product = create(:product)
      variant = create(:product_variant, product: product)
      create(:product_variant, product: product)

      expect { variant.destroy! }.to change(described_class, :count).by(-1)
    end
  end

  describe "#decrement_stock!" do
    it "reduces the stock quantity" do
      variant = create(:product_variant, stock_quantity: 10)

      variant.decrement_stock!(3)

      expect(variant.stock_quantity).to eq(7)
      expect(variant.reload.stock_quantity).to eq(7)
    end

    it "allows consuming the last remaining stock" do
      variant = create(:product_variant, stock_quantity: 2)

      variant.decrement_stock!(2)

      expect(variant.reload.stock_quantity).to eq(0)
    end

    it "raises instead of going negative" do
      variant = create(:product_variant, stock_quantity: 1)

      expect { variant.decrement_stock!(2) }.to raise_error(ProductVariant::InsufficientStock)
      expect(variant.reload.stock_quantity).to eq(1)
    end

    # The whole point of the WHERE-guarded UPDATE: a stale in-memory copy
    # must not be able to re-spend stock another request already took.
    it "does not oversell when a stale instance decrements after another has" do
      variant = create(:product_variant, stock_quantity: 1)
      stale = described_class.find(variant.id)

      variant.decrement_stock!(1)

      expect { stale.decrement_stock!(1) }.to raise_error(described_class::InsufficientStock)
      expect(variant.reload.stock_quantity).to eq(0)
    end
  end
end
