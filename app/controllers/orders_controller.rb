class OrdersController < ApplicationController
  # Scoped to the signed-in fan's own orders: an order carries an address
  # and what someone paid, so another fan's id must not resolve here.
  def index
    @orders = current_user.orders.includes(:band, :order_items).order(created_at: :desc)
  end

  def show
    @order = current_user.orders.includes(:band, :order_items, :shipping_address).find(params[:id])
  end
end
