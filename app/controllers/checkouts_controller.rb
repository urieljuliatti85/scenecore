class CheckoutsController < ApplicationController
  before_action :set_cart

  def new
    @shipping_address = ShippingAddress.new
  end

  # Turns the cart into a pending order and hands the fan to Stripe. The
  # order stays pending and no stock moves until the webhook confirms
  # payment — a failed or abandoned checkout must not consume inventory.
  def create
    @shipping_address = ShippingAddress.new(shipping_address_params)

    unless @cart.band.store_checkout_ready?
      return redirect_to cart_path, alert: "#{@cart.band.name} can't take payments yet."
    end

    order = nil
    ActiveRecord::Base.transaction do
      order = build_order
      order.save!
      @shipping_address.order = order
      @shipping_address.save!
    end

    url = StoreCheckoutSessionCreator.call(
      order,
      success_url: order_url(order),
      cancel_url: cart_url
    )

    @cart.converted!
    redirect_to url, allow_other_host: true
  rescue ActiveRecord::RecordInvalid
    render :new, status: :unprocessable_entity
  rescue StoreCheckoutSessionCreator::Error => e
    order&.destroy
    redirect_to cart_path, alert: e.message
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
