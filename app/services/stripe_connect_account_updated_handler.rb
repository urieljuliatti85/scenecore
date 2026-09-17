# Keeps Band#stripe_connect_status in sync with Stripe's own view of the
# connected account (ADR-007) — a band's onboarding can complete,
# regress (e.g. a requested capability gets restricted), or need more
# information, and Stripe communicates all of that via account.updated
# rather than a one-time "onboarding complete" signal.
class StripeConnectAccountUpdatedHandler
  def self.call(account)
    new(account).call
  end

  def initialize(account)
    @account = account
  end

  def call
    band = Band.find_by(stripe_connect_account_id: @account.id)
    return if band.nil?

    band.update!(stripe_connect_status: status_for(@account))
  end

  private

  def status_for(account)
    return :restricted if account.requirements&.disabled_reason.present?
    return :active if account.charges_enabled && account.payouts_enabled

    :onboarding
  end
end
