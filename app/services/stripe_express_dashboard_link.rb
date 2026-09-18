# Express Dashboard login links are short-lived and single-use. Minting one
# on each click keeps the connected account behind SceneCore's band-scoped
# authorization instead of exposing a generic Stripe dashboard URL.
class StripeExpressDashboardLink
  Error = Class.new(StandardError)

  def self.call(band)
    raise Error, "This band does not have an active Stripe account." unless band.payouts_ready?

    StripeClient.instance.v1.accounts.login_links
      .create(band.stripe_connect_account_id)
      .url
  rescue Stripe::StripeError
    raise Error, "Could not open this band's Stripe dashboard."
  end
end
