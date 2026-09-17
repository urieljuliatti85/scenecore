class CheckoutsController < ApplicationController
  before_action :set_cart

  def new
    @shipping_address = ShippingAddress.new
  end

  # Turns the cart into a pending order with its address. Payment is not
  # wired yet (roadmap 8.1 step 6), so the order stops at pending and no
  # stock is decremented — that belongs with the Stripe Connect session,
  # where a failed payment must not have already consumed inventory.
  def create
    @shipping_address = ShippingAddress.new(shipping_address_params)

    order = nil
    ActiveRecord::Base.transaction do
      order = build_order
      order.save!
      @shipping_address.order = order
      @shipping_address.save!
      @cart.converted!
    end

    redirect_to cart_path, notice: "Order ##{order.id} placed. Payment is not available yet."
  rescue ActiveRecord::RecordInvalid
    render :new, status: :unprocessable_entity
  end

  private

  def set_cart
    @cart = current_user.carts.includes(cart_items: { product_variant: :product }).find_by(status: :active)

    redirect_to cart_path, alert: "Your cart is empty." if @cart.nil? || @cart.cart_items.empty?
  end

  # Amounts are snapshotted onto the order rather than read back through the
  # variant later, so editing a product's price does not rewrite what someone
  # already agreed to pay (docs/database.md Orders).
  def build_order
    subtotal = @cart.subtotal_cents
    shipping = @cart.shipping_cents
    total = subtotal + shipping

    order = current_user.orders.new(
      band: @cart.band,
      subtotal_cents: subtotal,
      shipping_cents: shipping,
      total_cents: total,
      platform_fee_cents: (subtotal * Order::PLATFORM_FEE_RATE).round
    )

    @cart.cart_items.each do |item|
      order.order_items.new(
        product_variant: item.product_variant,
        product_name: item.product_variant.product.name,
        variant_name: item.product_variant.name,
        unit_price_cents: item.product_variant.price_cents,
        quantity: item.quantity
      )
    end

    order
  end

  def shipping_address_params
    params.require(:shipping_address).permit(
      :recipient_name, :line1, :line2, :city, :state, :postal_code, :country
    )
  end
end
