# Reads a band's connected account straight from Stripe and re-syncs
# Band#stripe_connect_status from it.
#
# Status normally arrives by webhook (account.updated). That leaves one
# failure mode with no way out: a webhook that never lands — endpoint
# misconfigured, a delivery that failed while the app was down, or local
# development without `stripe listen` — strands the band on "onboarding"
# even after Stripe has approved the account, with checkout blocked and
# nothing in the UI able to correct it.
#
# Polling on every page load would be wasteful, so this is called only
# while the band is mid-onboarding, where the status is expected to change
# and the band is the one actively waiting on it.
class StripeConnectStatusRefresher
  Error = Class.new(StandardError)

  # v2 omits configuration unless it is asked for by name. Without this the
  # capability path reads nil and the account looks unstarted rather than
  # approved — the exact failure this class exists to fix.
  INCLUDE = [ "configuration.recipient", "configuration.merchant", "requirements" ].freeze

  def self.call(band)
    new(band).call
  end

  def initialize(band)
    @band = band
  end

  def call
    return if @band.stripe_connect_account_id.blank?

    account = StripeClient.instance.v2.core.accounts.retrieve(
      @band.stripe_connect_account_id,
      include: INCLUDE
    )

    StripeConnectAccountUpdatedHandler.call(account)
  rescue Stripe::StripeError => e
    raise Error, "Could not read this band's Stripe account: #{e.message}"
  end
end
