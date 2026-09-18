require "rails_helper"

RSpec.describe StripeStoreRefundHandler do
  let(:order) do
    create(:order, :paid, stripe_checkout_session_id: "cs_1",
                          stripe_payment_intent_id: "pi_1", stripe_refund_id: "re_1",
                          refund_status: "pending")
  end

  def refund(id: "re_1", status: "succeeded", payment_intent: "pi_1", order_id: order.id)
    instance_double(Stripe::Refund, id: id, status: status, payment_intent: payment_intent,
                                    metadata: { "order_id" => order_id.to_s })
  end

  it "marks the order refunded when Stripe succeeds" do
    described_class.call(refund)

    expect(order.reload).to be_refunded
    expect(order.refund_status).to eq("succeeded")
    expect(order.refunded_at).to be_present
  end

  it "does not restore stock automatically" do
    product = create(:product, band: order.band)
    variant = create(:product_variant, product: product, stock_quantity: 3)
    create(:order_item, order: order, product_variant: variant, quantity: 1)

    expect { described_class.call(refund) }
      .not_to change { variant.reload.stock_quantity }
  end

  it "records a failed refund without changing the fulfilment state" do
    described_class.call(refund(status: "failed"))

    expect(order.reload).to be_paid
    expect(order.refund_status).to eq("failed")
    expect(order.refunded_at).to be_nil
  end

  it "finds an older order from trusted refund metadata" do
    order.update!(stripe_refund_id: nil, refund_status: nil)

    described_class.call(refund)

    expect(order.reload.stripe_refund_id).to eq("re_1")
    expect(order).to be_refunded
  end

  it "ignores a refund for another PaymentIntent" do
    described_class.call(refund(payment_intent: "pi_other"))

    expect(order.reload).to be_paid
    expect(order.refund_status).to eq("pending")
  end

  it "does not let an older event replace a terminal result" do
    described_class.call(refund)
    refunded_at = order.reload.refunded_at

    described_class.call(refund(status: "pending"))

    expect(order.reload).to be_refunded
    expect(order.refund_status).to eq("succeeded")
    expect(order.refunded_at).to eq(refunded_at)
  end

  it "ignores a refund that cannot be matched to an order" do
    order

    expect { described_class.call(refund(id: "re_other", order_id: 0)) }
      .not_to change { order.reload.attributes }
  end
end
