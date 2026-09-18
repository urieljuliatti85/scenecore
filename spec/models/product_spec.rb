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

  describe "member priority access" do
    let(:band) { create(:band) }

    it "requires both a level and an end time" do
      expect(build(:product, early_access_level: :core_member)).not_to be_valid
      expect(build(:product, early_access_until: 1.day.from_now)).not_to be_valid
    end

    it "lets only the configured level and higher access a priority product" do
      product = create(:product, band: band, early_access_level: :supporter, early_access_until: 1.day.from_now)
      fan = create(:user)
      supporter = create(:user)
      core_member = create(:user)
      create(:membership, band: band, user: fan, level: :fan)
      create(:membership, band: band, user: supporter, level: :supporter)
      create(:membership, band: band, user: core_member, level: :core_member)

      expect(product.available_to?(nil)).to be false
      expect(product.available_to?(fan)).to be false
      expect(product.available_to?(supporter)).to be true
      expect(product.available_to?(core_member)).to be true
    end

    it "opens the product to everyone after the priority window" do
      product = create(:product, band: band, early_access_level: :core_member, early_access_until: 1.minute.ago)

      expect(product.available_to?(nil)).to be true
      expect(product.required_level).to be_nil
    end
  end

  it "destroys its variants when destroyed" do
    product = create(:product)
    create(:product_variant, product: product)

    expect { product.destroy! }.to change(ProductVariant, :count).by(-1)
  end

  describe "#shipping_cents_for" do
    let(:band) { create(:band, :approved) }
    let(:product) { create(:product, band: band, shipping_cents: 900) }

    # Zones arrived after bands were already selling, so a band that has
    # configured none keeps charging its flat per-product rate rather than
    # having its store close.
    context "when the band has no zones" do
      it "charges the product's flat rate anywhere" do
        expect(product.shipping_cents_for("JP")).to eq(900)
      end
    end

    context "when the band has zones" do
      let!(:domestic) { create(:shipping_zone, band: band, name: "Brazil", shipping_cents: 1_500, country_codes: [ "BR" ]) }

      it "charges the zone's rate, not the product's flat rate" do
        expect(product.shipping_cents_for("BR")).to eq(1_500)
      end

      it "refuses a country no zone covers" do
        expect(product.shipping_cents_for("JP")).to be_nil
      end

      it "prefers the product's own override for that zone" do
        create(:product_shipping_rate, product: product, shipping_zone: domestic, shipping_cents: 300)

        expect(product.reload.shipping_cents_for("BR")).to eq(300)
      end

      # An override of 0 is deliberate free shipping, distinct from having
      # no override at all — so it must not fall back to the zone's rate.
      it "honours an override of zero" do
        create(:product_shipping_rate, product: product, shipping_zone: domestic, shipping_cents: 0)

        expect(product.reload.shipping_cents_for("BR")).to eq(0)
      end

      it "leaves other zones on their own rate" do
        abroad = create(:shipping_zone, band: band, name: "Europe", shipping_cents: 4_000, country_codes: [ "PT" ])
        create(:product_shipping_rate, product: product, shipping_zone: domestic, shipping_cents: 300)

        expect(product.reload.shipping_cents_for("PT")).to eq(4_000)
        expect(abroad.reload.shipping_cents).to eq(4_000)
      end
    end
  end
end
