# Finds or creates the Stripe Product+Price that represents a given
# band's membership level, so a Checkout Session always has a real
# recurring Price to point at. The mapping is cached in
# BandMembershipPrice (our own database), not resolved via Stripe's
# Search API on every call — Search has known indexing lag, so relying
# on it here could create duplicate Products under concurrent checkouts
# for the same band+level.
class StripePriceResolver
  Error = Class.new(StandardError)

  CURRENCY = "usd".freeze

  def self.resolve(band, level)
    new(band, level).resolve
  end

  def initialize(band, level)
    @band = band
    @level = level.to_s
  end

  def resolve
    existing = BandMembershipPrice.find_by(band: @band, level: @level)
    return existing.stripe_price_id if existing

    create_and_cache!
  end

  private

  def create_and_cache!
    product = StripeClient.instance.v1.products.create(
      name: "#{@band.name} — #{@level.humanize} membership",
      metadata: { band_id: @band.id, level: @level }
    )

    price = StripeClient.instance.v1.prices.create(
      product: product.id,
      currency: CURRENCY,
      unit_amount: Membership::PRICES_IN_CENTS.fetch(@level),
      recurring: { interval: "month" },
      metadata: { band_id: @band.id, level: @level }
    )

    record = BandMembershipPrice.create!(
      band: @band,
      level: @level,
      stripe_product_id: product.id,
      stripe_price_id: price.id
    )

    record.stripe_price_id
  rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
    # Lost a race with a concurrent resolve for the same band+level: the
    # other request already cached a price, so use that one instead of
    # leaving an orphaned Product/Price behind on Stripe's side.
    BandMembershipPrice.find_by!(band: @band, level: @level).stripe_price_id
  rescue Stripe::StripeError => e
    raise Error, "Could not create a Stripe price for this band and level: #{e.message}"
  end
end
