# The band's side of an order: what was bought, where to send it, and
# moving it along as it is packed and shipped. The fan's own view lives in
# OrdersController — same records, different questions asked of them.
class BandOrdersController < ApplicationController
  before_action :set_band
  before_action :set_order

  def show
    authorize @order, policy_class: OrderPolicy
  end

  def fulfil
    authorize @order, :fulfil?, policy_class: OrderPolicy

    @order.advance_fulfilment!
    redirect_back fallback_location: band_path(@band, tab: "orders"),
                  notice: "Order ##{@order.id} marked #{@order.status}."
  end

  def refund
    authorize @order, :refund?, policy_class: OrderPolicy

    StoreOrderRefundCreator.call(@order)
    redirect_to band_order_path(@band, @order),
                notice: "Full refund requested. Waiting for Stripe to confirm it."
  rescue StoreOrderRefundCreator::Error => e
    redirect_to band_order_path(@band, @order), alert: e.message
  end

  private

  def set_band
    @band = Band.find(params[:band_id])
  end

  # Scoped through the band, so an order id belonging to another band does
  # not resolve here even before the policy runs.
  def set_order
    @order = @band.orders.includes(:user, :order_items, :shipping_address).find(params[:id])
  end
end
