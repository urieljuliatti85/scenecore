class CartsController < ApplicationController
  before_action :set_cart, only: [ :show, :destroy ]

  def show
    @pending_variant = ProductVariant.find_by(id: params[:pending_variant_id]) if params[:pending_variant_id]
  end

  # A cart holds one band's products at a time (ADR-003). Adding another
  # band's item does not silently discard the current one: the fan is sent
  # back to confirm, and only a request carrying confirm_switch replaces it.
  def add
    variant = ProductVariant.find(params[:product_variant_id])
    band = variant.product.band

    # A band the platform has not approved (or has suspended) has no public
    # Store, so its products cannot be bought through a direct link either.
    unless band.approved? && variant.product.published? && variant.product.available_to?(current_user)
      return redirect_back fallback_location: root_path, alert: "That product isn't available."
    end

    cart = current_user.carts.find_by(status: :active)

    if cart && cart.band_id != band.id && params[:confirm_switch].blank?
      return redirect_to cart_path(pending_variant_id: variant.id), alert: "Your cart has items from #{cart.band.name}."
    end

    if cart && cart.band_id != band.id
      cart.abandoned!
      cart = nil
    end

    cart ||= current_user.carts.create!(band: band)

    item = cart.cart_items.find_or_initialize_by(product_variant: variant)
    added = [ quantity_param, 1 ].max
    item.quantity = item.new_record? ? added : item.quantity + added

    if item.quantity > variant.stock_quantity
      return redirect_to cart_path, alert: "Only #{variant.stock_quantity} left of #{variant.name}."
    end

    item.save!
    redirect_to cart_path, notice: "Added to your cart."
  end

  def update_item
    cart = current_user.carts.find_by!(status: :active)
    item = cart.cart_items.find(params[:cart_item_id])

    if quantity_param > item.product_variant.stock_quantity
      return redirect_to cart_path, alert: "Only #{item.product_variant.stock_quantity} left of #{item.product_variant.name}."
    end

    if quantity_param.zero?
      item.destroy!
      return redirect_to cart_path, notice: "Item removed."
    end

    item.update!(quantity: quantity_param)
    redirect_to cart_path, notice: "Cart updated."
  end

  def remove_item
    cart = current_user.carts.find_by!(status: :active)
    cart.cart_items.find(params[:cart_item_id]).destroy!

    redirect_to cart_path, notice: "Item removed."
  end

  def destroy
    @cart&.abandoned!

    redirect_to cart_path, notice: "Cart emptied."
  end

  private

  def set_cart
    @cart = current_user.carts.includes(cart_items: { product_variant: :product }).find_by(status: :active)
  end

  # Quantity arrives from a form field, so it is clamped rather than trusted:
  # a negative or absent value must not turn into a negative line quantity,
  # which the cart_items check constraint would reject with a 500.
  def quantity_param
    [ params[:quantity].to_i, 0 ].max.clamp(0, 99)
  end
end
