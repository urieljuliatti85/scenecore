# Thin wrapper around a configured Stripe::StripeClient instance. Per
# Stripe's own guidance, the deprecated global `Stripe.api_key = ...`
# pattern is never used — every caller gets a client built from
# credentials, the same way SpotifyClient reads its own credentials.
class StripeClient
  Error = Class.new(StandardError)

  def self.instance
    @instance ||= Stripe::StripeClient.new(Rails.application.credentials.dig(:stripe, :secret_key))
  end
end
