require "rails_helper"

RSpec.describe StripePlatformStatus do
  let(:accounts_service) { instance_double(Stripe::AccountService) }
  let(:webhook_endpoints_service) { instance_double(Stripe::WebhookEndpointService) }
  let(:event_destinations_service) { instance_double(Stripe::V2::Core::EventDestinationService) }
  let(:v1) do
    instance_double(
      Stripe::V1Services,
      accounts: accounts_service,
      webhook_endpoints: webhook_endpoints_service
    )
  end
  let(:core) { instance_double(Stripe::V2::CoreService, event_destinations: event_destinations_service) }
  let(:v2) { instance_double(Stripe::V2Services, core: core) }
  let(:client) { instance_double(Stripe::StripeClient, v1: v1, v2: v2) }
  let(:webhook_url) { "https://scenecore.example/stripe/webhooks" }

  def service(**overrides)
    described_class.new(
      **{
        webhook_url: webhook_url,
        client: client,
        secret_key: "sk_live_example",
        snapshot_webhook_secret: "whsec_snapshot",
        connect_webhook_secret: "whsec_connect"
      }.merge(overrides)
    )
  end

  before do
    requirements = double(
      currently_due: [ "representative.verification.document" ],
      past_due: [],
      pending_verification: [ "representative.id_number" ],
      disabled_reason: "requirements.past_due"
    )
    account = double(
      charges_enabled: false,
      payouts_enabled: true,
      details_submitted: true,
      requirements: requirements
    )
    snapshot_endpoint = double(url: webhook_url, status: "enabled")
    connect_endpoint = double(
      type: "webhook_endpoint",
      webhook_endpoint: double(url: webhook_url),
      status: "enabled"
    )

    allow(accounts_service).to receive(:retrieve_current).and_return(account)
    allow(webhook_endpoints_service).to receive(:list).with(limit: 100)
      .and_return(double(data: [ snapshot_endpoint ]))
    allow(event_destinations_service).to receive(:list).with(limit: 100)
      .and_return(double(data: [ connect_endpoint ]))
  end

  it "reports platform, webhook and latest event status without exposing secrets" do
    last_event = create(:stripe_webhook_event, processed_at: 3.minutes.ago)

    result = service.call

    expect(result.mode).to eq(:live)
    expect(result.secret_key_configured).to be(true)
    expect(result.account).to have_attributes(
      reachable: true,
      charges_enabled: false,
      payouts_enabled: true,
      details_submitted: true,
      pending_requirements_count: 2,
      disabled_reason: "requirements.past_due"
    )
    expect(result.snapshot_webhook).to have_attributes(secret_configured: true, endpoint_enabled: true, error: nil)
    expect(result.connect_webhook).to have_attributes(secret_configured: true, endpoint_enabled: true, error: nil)
    expect(result.last_webhook_at).to be_within(1.second).of(last_event.processed_at)
    expect(result.to_h.to_s).not_to include("sk_live_example", "whsec_snapshot", "whsec_connect")
  end

  it "reports missing configuration without calling Stripe" do
    result = service(secret_key: nil, snapshot_webhook_secret: nil, connect_webhook_secret: nil).call

    expect(result.mode).to eq(:unconfigured)
    expect(result.account).to have_attributes(reachable: false, error: "Stripe secret key is not configured")
    expect(result.snapshot_webhook).to have_attributes(secret_configured: false, endpoint_enabled: false)
    expect(result.connect_webhook).to have_attributes(secret_configured: false, endpoint_enabled: false)
    expect(accounts_service).not_to have_received(:retrieve_current)
  end

  it "degrades account status when Stripe is unavailable" do
    allow(accounts_service).to receive(:retrieve_current).and_raise(Stripe::APIConnectionError.new("down"))

    result = service.call

    expect(result.account).to have_attributes(reachable: false, error: "Stripe could not be reached")
    expect(result.snapshot_webhook.endpoint_enabled).to be(true)
    expect(result.connect_webhook.endpoint_enabled).to be(true)
  end

  it "reports a configured secret with no matching enabled destination as action required" do
    allow(webhook_endpoints_service).to receive(:list).and_return(double(data: []))
    allow(event_destinations_service).to receive(:list).and_return(double(data: []))

    result = service.call

    expect(result.snapshot_webhook).to have_attributes(secret_configured: true, endpoint_enabled: false, error: nil)
    expect(result.connect_webhook).to have_attributes(secret_configured: true, endpoint_enabled: false, error: nil)
  end
end
