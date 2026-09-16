require "rails_helper"

RSpec.describe StripePriceResolver do
  let(:band) { create(:band) }
  let(:products_service) { instance_double(Stripe::ProductService) }
  let(:prices_service) { instance_double(Stripe::PriceService) }
  let(:v1) { instance_double(Stripe::V1Services, products: products_service, prices: prices_service) }
  let(:stripe_client) { instance_double(Stripe::StripeClient, v1: v1) }

  before do
    allow(StripeClient).to receive(:instance).and_return(stripe_client)
  end

  describe ".resolve" do
    it "returns the cached price id without calling Stripe when one already exists" do
      create(:band_membership_price, band: band, level: :supporter, stripe_price_id: "price_existing")
      allow(products_service).to receive(:create)

      price_id = described_class.resolve(band, :supporter)

      expect(price_id).to eq("price_existing")
      expect(products_service).not_to have_received(:create)
    end

    it "creates a Stripe product and price, then caches it, when none exists yet" do
      product = instance_double(Stripe::Product, id: "prod_new")
      price = instance_double(Stripe::Price, id: "price_new")
      allow(products_service).to receive(:create).and_return(product)
      allow(prices_service).to receive(:create).and_return(price)

      price_id = described_class.resolve(band, :fan)

      expect(price_id).to eq("price_new")
      expect(products_service).to have_received(:create).with(
        hash_including(metadata: { band_id: band.id, level: "fan" })
      )
      expect(prices_service).to have_received(:create).with(
        hash_including(product: "prod_new", unit_amount: 300, currency: "usd")
      )

      cached = BandMembershipPrice.find_by(band: band, level: "fan")
      expect(cached.stripe_price_id).to eq("price_new")
      expect(cached.stripe_product_id).to eq("prod_new")
    end

    it "reuses the winner's cached price when it loses a race to create one" do
      allow(products_service).to receive(:create) do
        create(:band_membership_price, band: band, level: :fan, stripe_price_id: "price_from_winner")
        instance_double(Stripe::Product, id: "prod_loser")
      end
      allow(prices_service).to receive(:create).and_return(instance_double(Stripe::Price, id: "price_loser"))

      price_id = described_class.resolve(band, :fan)

      expect(price_id).to eq("price_from_winner")
      expect(BandMembershipPrice.where(band: band, level: "fan").count).to eq(1)
    end

    it "wraps a Stripe error so the controller can rescue it without depending on the Stripe gem directly" do
      allow(products_service).to receive(:create).and_raise(Stripe::APIConnectionError.new("network down"))

      expect { described_class.resolve(band, :fan) }.to raise_error(StripePriceResolver::Error)
    end
  end
end
