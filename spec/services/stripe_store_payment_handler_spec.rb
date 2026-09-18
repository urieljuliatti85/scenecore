require "rails_helper"

RSpec.describe StripeStorePaymentHandler do
  let(:band) do
    create(:band, :approved, stripe_connect_status: :active, stripe_connect_account_id: "acct_1")
  end
  let(:product) { create(:product, :published, band: band, name: "Vinyl") }
  let(:variant) { product.variants.create!(name: "Standard", sku: "V-1", price_cents: 12_000, stock_quantity: 5) }

  let(:order) do
    order = create(:user).orders.create!(
      band: band, subtotal_cents: 24_000, shipping_cents: 0,
      total_cents: 24_000, platform_fee_cents: 2_400,
      stripe_checkout_session_id: "cs_store_1"
    )
    order.order_items.create!(product_variant: variant, product_name: "Vinyl",
                              variant_name: "Standard", unit_price_cents: 12_000, quantity: 2)
    order
  end

  def session(id: "cs_store_1", payment_status: "paid", payment_intent: "pi_store_1")
    instance_double(Stripe::Checkout::Session, id: id, payment_status: payment_status,
                                              payment_intent: payment_intent)
  end

  it "marks the order paid" do
    order

    described_class.call(session)

    expect(order.reload).to be_paid
    expect(order.stripe_payment_intent_id).to eq("pi_store_1")
  end

  it "consumes the stock the order claimed" do
    order

    expect { described_class.call(session) }.to change { variant.reload.stock_quantity }.from(5).to(3)
  end

  # Stripe retries until it gets a 2xx and can deliver the same event twice.
  # Decrementing again would sell inventory nobody bought.
  it "does not consume stock twice for a redelivered event" do
    order
    described_class.call(session)

    expect { described_class.call(session) }.not_to change { variant.reload.stock_quantity }
  end

  it "ignores a session that does not belong to an order" do
    order

    expect { described_class.call(session(id: "cs_unknown")) }
      .not_to change { variant.reload.stock_quantity }

    expect(order.reload).to be_pending
  end

  it "ignores a session that has not been paid" do
    order

    described_class.call(session(payment_status: "unpaid"))

    expect(order.reload).to be_pending
    expect(variant.reload.stock_quantity).to eq(5)
  end

  it "accepts a zero-amount order Stripe reports as requiring no payment" do
    order

    described_class.call(session(payment_status: "no_payment_required", payment_intent: nil))

    expect(order.reload).to be_paid
  end

  # The charge has already gone through by the time this runs. Losing the
  # order or letting Stripe retry forever would both be worse than recording
  # a paid order the band has to sort out.
  context "when the stock ran out while the fan was paying" do
    before { variant.update!(stock_quantity: 1) }

    it "still records the order as paid" do
      order

      described_class.call(session)

      expect(order.reload).to be_paid
    end

    it "leaves the stock alone rather than driving it negative" do
      order

      described_class.call(session)

      expect(variant.reload.stock_quantity).to eq(1)
    end

    it "logs the shortfall for the band to resolve" do
      order
      allow(Rails.logger).to receive(:error)

      described_class.call(session)

      expect(Rails.logger).to have_received(:error).with(/Store order #{order.id}/)
    end
  end
end
