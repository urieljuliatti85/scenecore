# Keeps Band#stripe_connect_status in sync with Stripe's own view of the
# connected account (ADR-007), reading the v2 capability status rather
# than the v1 charges_enabled/payouts_enabled flags, which a v2 account
# does not populate — a band's onboarding can complete,
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
    case transfer_capability_status(account)
    when "active" then :active
    when "restricted", "unsupported" then :restricted
    when nil then legacy_status_for(account)
    else :onboarding
    end
  end

  # The v2 path: configuration.recipient.capabilities.stripe_balance
  # .stripe_transfers.status, defended against intermediate keys being
  # absent while onboarding is still in progress.
  def transfer_capability_status(account)
    account
      .try(:configuration)&.try(:recipient)
      &.try(:capabilities)&.try(:stripe_balance)
      &.try(:stripe_transfers)&.try(:status)
  end

  # The v1 snapshot payload, which account.updated still delivers. Kept as
  # the fallback rather than the primary read: Stripe documents the
  # capability path as the way to check readiness, and these flags are
  # deprecated for accounts created through v2.
  def legacy_status_for(account)
    return :restricted if account.try(:requirements)&.try(:disabled_reason).present?
    return :active if account.try(:charges_enabled) && account.try(:payouts_enabled)

    :onboarding
  end
end
