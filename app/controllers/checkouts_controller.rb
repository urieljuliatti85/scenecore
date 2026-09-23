class CheckoutsController < ApplicationController
  before_action :set_cart
  helper_method :shipping_country_options

  def new
    @shipping_address = ShippingAddress.new(country: default_country)
  end

  # Turns the cart into a pending order and hands the fan to Stripe. The
  # order stays pending and no stock moves until the webhook confirms
  # payment — a failed or abandoned checkout must not consume inventory.
  def create
    @shipping_address = ShippingAddress.new(shipping_address_params)

    # The cart may have been filled before the band was suspended, so its
    # standing is checked again at the moment money would move.
    unless @cart.band.approved?
      return redirect_to cart_path, alert: "#{@cart.band.name} isn't selling right now."
    end

    unless @cart.band.payouts_ready?
      return redirect_to cart_path, alert: "#{@cart.band.name} can't take payments yet."
    end

    # A product may have entered a members-only priority window after it
    # was put in the cart. Re-check on the server before charging so a
    # cached cart or crafted request cannot bypass that window.
    unless @cart.cart_items.all? { |item| item.product_variant.product.published? && item.product_variant.product.available_to?(current_user) }
      return redirect_to cart_path, alert: "One or more products in your cart aren't available to you yet."
    end

    # A band lists the destinations it serves, so an unlisted country is a
    # refusal rather than a rate of zero. Checked here on the server: the
    # country select only narrows what is easy to pick, and an address for
    # an unserved country must not become an order at a guessed price.
    if @cart.shipping_cents_for(@shipping_address.country).nil?
      @shipping_address.errors.add(:country, "is not a destination #{@cart.band.name} ships to")
      return render :new, status: :unprocessable_entity
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

  # Pre-selects the band's own country, which is the commonest destination
  # for a small band's orders, but only when it is one the band actually
  # ships to.
  def default_country
    code = @cart.band.country_code
    code if @cart.shipping_cents_for(code)
  end

  # The destinations this cart can be shipped to, for the country select.
  def shipping_country_options
    zones = @cart.band.shipping_zones.includes(:zone_countries)
    return Country.options if zones.empty?

    codes = zones.flat_map(&:country_codes).uniq
    Country.options.select { |_name, code| codes.include?(code) }
  end

  def set_cart
    @cart = current_user.carts.includes(cart_items: { product_variant: :product }).find_by(status: :active)

    redirect_to cart_path, alert: "Your cart is empty." if @cart.nil? || @cart.cart_items.empty?
  end

  # Amounts are snapshotted onto the order rather than read back through the
  # variant later, so editing a product's price does not rewrite what someone
  # already agreed to pay (docs/database.md Orders).
  def build_order
    subtotal = @cart.subtotal_cents
    shipping = @cart.shipping_cents_for(@shipping_address.country)
    total = subtotal + shipping

    order = current_user.orders.new(
      band: @cart.band,
      subtotal_cents: subtotal,
      shipping_cents: shipping,
      total_cents: total,
      platform_fee_cents: (subtotal * PlatformSetting.current.store_fee_percentage / 100.0).round
    )

    @cart.cart_items.each do |item|
      order.order_items.new(
        product_variant: item.product_variant,
        product_name: item.product_variant.product.name,
        variant_name: item.product_variant.name,
        unit_price_cents: @cart.discounted_unit_price_cents(item.product_variant),
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
