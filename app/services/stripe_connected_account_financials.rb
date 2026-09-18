# Reads the money Stripe currently holds for one connected band account.
# The platform key authenticates the request, while stripe_account scopes it
# to that band — omitting it would show SceneCore's own balance instead.
class StripeConnectedAccountFinancials
  Error = Class.new(StandardError)

  Balance = Data.define(:currency, :available_cents, :pending_cents)
  Payout = Data.define(:currency, :amount_cents, :arrival_at)
  Summary = Data.define(:balances, :next_payout)

  def self.call(band)
    new(band).call
  end

  def initialize(band)
    @band = band
  end

  def call
    raise Error, "This band does not have an active Stripe account." unless @band.payouts_ready?

    options = { stripe_account: @band.stripe_connect_account_id }
    client = StripeClient.instance.v1
    balance = client.balance.retrieve({}, options)
    pending_payouts = client.payouts.list({ status: "pending", limit: 100 }, options)

    Summary.new(
      balances: balances_from(balance),
      next_payout: payout_from(pending_payouts.data.min_by(&:arrival_date))
    )
  rescue Stripe::StripeError
    raise Error, "Could not read this band's Stripe balance."
  end

  private

  def balances_from(balance)
    available = amounts_by_currency(balance.available)
    pending = amounts_by_currency(balance.pending)

    (available.keys | pending.keys).sort.map do |currency|
      Balance.new(
        currency: currency,
        available_cents: available[currency],
        pending_cents: pending[currency]
      )
    end
  end

  def amounts_by_currency(amounts)
    amounts.each_with_object(Hash.new(0)) do |amount, totals|
      totals[amount.currency] += amount.amount
    end
  end

  def payout_from(payout)
    return if payout.nil?

    Payout.new(
      currency: payout.currency,
      amount_cents: payout.amount,
      arrival_at: Time.zone.at(payout.arrival_date)
    )
  end
end
