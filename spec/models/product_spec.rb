require "rails_helper"

RSpec.describe Product do
  describe "validations" do
    it "requires a name" do
      expect(build(:product, name: nil)).not_to be_valid
    end
  end

  describe "visibility" do
    it "defaults to draft" do
      expect(described_class.new).to be_draft
    end

    it "excludes drafts from the published scope" do
      published = create(:product, :published)
      create(:product)

      expect(described_class.published).to contain_exactly(published)
    end
  end

  it "destroys its variants when destroyed" do
    product = create(:product)
    create(:product_variant, product: product)

    expect { product.destroy! }.to change(ProductVariant, :count).by(-1)
  end
end
