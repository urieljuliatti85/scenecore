class StripePlatformStatus
  Account = Data.define(
    :reachable,
    :charges_enabled,
    :payouts_enabled,
    :details_submitted,
    :pending_requirements_count,
    :disabled_reason,
    :error
  )

  Webhook = Data.define(:secret_configured, :endpoint_enabled, :error)

  Result = Data.define(
    :secret_key_configured,
    :mode,
    :account,
    :snapshot_webhook,
    :connect_webhook,
    :last_webhook_at
  )

  def self.call(webhook_url:)
    new(webhook_url: webhook_url).call
  end

  def initialize(
    webhook_url:,
    client: nil,
    secret_key: Rails.application.credentials.dig(:stripe, :secret_key),
    snapshot_webhook_secret: Rails.application.credentials.dig(:stripe, :webhook_secret),
    connect_webhook_secret: ENV["STRIPE_CONNECT_WEBHOOK_SECRET"].presence ||
      Rails.application.credentials.dig(:stripe, :connect_webhook_secret)
  )
    @webhook_url = webhook_url
    @client = client
    @secret_key = secret_key
    @snapshot_webhook_secret = snapshot_webhook_secret
    @connect_webhook_secret = connect_webhook_secret
  end

  def call
    Result.new(
      secret_key_configured: secret_key_configured?,
      mode: stripe_mode,
      account: account_status,
      snapshot_webhook: snapshot_webhook_status,
      connect_webhook: connect_webhook_status,
      last_webhook_at: StripeWebhookEvent.maximum(:processed_at)
    )
  end

  private

  def account_status
    return unavailable_account("Stripe secret key is not configured") unless secret_key_configured?

    account = client.v1.accounts.retrieve_current
    requirements = account.requirements
    pending_count = %i[currently_due past_due pending_verification].sum do |field|
      Array(requirements&.public_send(field)).size
    end

    Account.new(
      reachable: true,
      charges_enabled: account.charges_enabled,
      payouts_enabled: account.payouts_enabled,
      details_submitted: account.details_submitted,
      pending_requirements_count: pending_count,
      disabled_reason: requirements&.disabled_reason,
      error: nil
    )
  rescue Stripe::StripeError
    unavailable_account("Stripe could not be reached")
  end

  def snapshot_webhook_status
    endpoint_status(secret: @snapshot_webhook_secret) do
      endpoints = client.v1.webhook_endpoints.list(limit: 100).data
      endpoints.find { |endpoint| endpoint.url == @webhook_url }
    end
  end

  def connect_webhook_status
    endpoint_status(secret: @connect_webhook_secret) do
      destinations = client.v2.core.event_destinations.list(limit: 100).data
      destinations.find do |destination|
        destination.type == "webhook_endpoint" && destination.webhook_endpoint&.url == @webhook_url
      end
    end
  end

  def endpoint_status(secret:)
    return Webhook.new(secret_configured: secret.present?, endpoint_enabled: false, error: nil) unless secret_key_configured?

    endpoint = yield
    Webhook.new(
      secret_configured: secret.present?,
      endpoint_enabled: endpoint&.status == "enabled",
      error: nil
    )
  rescue Stripe::StripeError
    Webhook.new(secret_configured: secret.present?, endpoint_enabled: false, error: "Stripe could not be reached")
  end

  def unavailable_account(message)
    Account.new(
      reachable: false,
      charges_enabled: false,
      payouts_enabled: false,
      details_submitted: false,
      pending_requirements_count: 0,
      disabled_reason: nil,
      error: message
    )
  end

  def client
    @client ||= StripeClient.instance
  end

  def secret_key_configured?
    @secret_key.present?
  end

  def stripe_mode
    return :unconfigured unless secret_key_configured?
    return :live if @secret_key.match?(/\A(?:sk|rk)_live_/)
    return :test if @secret_key.match?(/\A(?:sk|rk)_test_/)

    :unknown
  end
end
