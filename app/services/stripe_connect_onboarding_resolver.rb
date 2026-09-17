# Starts or resumes a band's Stripe Connect onboarding (ADR-007). Reuses
# an existing connected account across calls the same way
# StripeCustomerResolver reuses a Customer — a band re-visiting the
# onboarding page mid-flow must not create a second Connect account.
#
# Accounts are created through the v2 API. Stripe rejects v1 account
# creation (`type: "express"`) for new integrations, and the v2 shape
# replaces that single type with three independent dimensions.
class StripeConnectOnboardingResolver
  Error = Class.new(StandardError)

  # SceneCore runs checkout on the band's behalf and takes a cut, which is
  # the marketplace shape: the platform is merchant of record, so it owns
  # pricing and absorbs negative balances, and the band gets the
  # lightweight cobranded dashboard rather than a full Stripe account to
  # administer. `losses_collector: "stripe"` is rejected outright with an
  # express dashboard, so these three move together.
  ACCOUNT_CONFIGURATION = {
    dashboard: "express",
    defaults: {
      responsibilities: {
        fees_collector: "application",
        losses_collector: "application"
      }
    }
  }.freeze

  # Stripe Accounts v2 requires merchant card_payments when requesting
  # recipient stripe_transfers. SceneCore still routes checkout through the
  # platform, but both configurations must exist on the connected account
  # for transfers to be enabled.
  CONNECT_CONFIGURATION = {
    merchant: {
      capabilities: {
        card_payments: { requested: true }
      }
    },
    recipient: {
      capabilities: {
        stripe_balance: {
          stripe_transfers: { requested: true }
        }
      }
    }
  }.freeze

  def self.resolve(band, contact_email:, return_url:, refresh_url:)
    new(
      band,
      contact_email: contact_email,
      return_url: return_url,
      refresh_url: refresh_url
    ).resolve
  end

  def initialize(band, contact_email:, return_url:, refresh_url:)
    @band = band
    @contact_email = contact_email
    @return_url = return_url
    @refresh_url = refresh_url
  end

  def resolve
    account_id = existing_or_new_account_id
    link = StripeClient.instance.v2.core.account_links.create(
      account: account_id,
      use_case: {
        type: "account_onboarding",
        account_onboarding: {
          configurations: [ "merchant", "recipient" ],
          return_url: @return_url,
          refresh_url: @refresh_url
        }
      }
    )

    @band.update!(stripe_connect_status: :onboarding) if @band.stripe_connect_not_started?
    link.url
  rescue Stripe::StripeError => e
    raise Error, "Could not start Stripe Connect onboarding for this band: #{e.message}"
  end

  private

  def existing_or_new_account_id
    if @band.stripe_connect_account_id.present?
      ensure_connect_configuration!(@band.stripe_connect_account_id)
      return @band.stripe_connect_account_id
    end

    account = StripeClient.instance.v2.core.accounts.create(
      **ACCOUNT_CONFIGURATION,
      contact_email: @contact_email,
      identity: { country: @band.country_code },
      configuration: CONNECT_CONFIGURATION,
      metadata: { band_id: @band.id.to_s }
    )

    @band.update!(stripe_connect_account_id: account.id)
    account.id
  rescue ActiveRecord::RecordNotUnique
    @band.reload
    ensure_connect_configuration!(@band.stripe_connect_account_id)
    @band.stripe_connect_account_id
  end

  def ensure_connect_configuration!(account_id)
    StripeClient.instance.v2.core.accounts.update(
      account_id,
      configuration: CONNECT_CONFIGURATION
    )
  end
end
