# Starts or resumes a band's Stripe Connect onboarding (ADR-007). Reuses
# an existing connected account across calls the same way
# StripeCustomerResolver reuses a Customer — a band re-visiting the
# onboarding page mid-flow must not create a second Connect account.
class StripeConnectOnboardingResolver
  Error = Class.new(StandardError)

  def self.resolve(band, return_url:, refresh_url:)
    new(band, return_url: return_url, refresh_url: refresh_url).resolve
  end

  def initialize(band, return_url:, refresh_url:)
    @band = band
    @return_url = return_url
    @refresh_url = refresh_url
  end

  def resolve
    account_id = existing_or_new_account_id
    link = StripeClient.instance.v1.account_links.create(
      account: account_id,
      type: "account_onboarding",
      return_url: @return_url,
      refresh_url: @refresh_url
    )

    @band.update!(stripe_connect_status: :onboarding) if @band.stripe_connect_not_started?
    link.url
  rescue Stripe::StripeError => e
    raise Error, "Could not start Stripe Connect onboarding for this band: #{e.message}"
  end

  private

  def existing_or_new_account_id
    return @band.stripe_connect_account_id if @band.stripe_connect_account_id.present?

    account = StripeClient.instance.v1.accounts.create(
      type: "express",
      metadata: { band_id: @band.id }
    )

    @band.update!(stripe_connect_account_id: account.id)
    account.id
  rescue ActiveRecord::RecordNotUnique
    @band.reload.stripe_connect_account_id
  end
end
