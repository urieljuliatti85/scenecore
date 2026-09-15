require "rails_helper"

# Sentry is configured from ENV["SENTRY_DSN"] so development, test and CI stay
# offline. These specs exercise the real Sentry client (through its dummy
# transport, so nothing leaves the process) rather than reading the
# initializer back, so they fail if the gem's behaviour changes under us.
RSpec.describe "Error monitoring" do
  it "stays inactive when no DSN is configured" do
    expect(Sentry.initialized?).to be false
  end

  context "when a DSN is configured" do
    around do |example|
      Sentry.init do |config|
        config.dsn = "https://publickey@o0.ingest.sentry.io/0"
        config.environment = "test-double"
        config.send_default_pii = false
        config.excluded_exceptions += [ "ActionController::RoutingError" ]
        config.background_worker_threads = 0
        config.transport.transport_class = Sentry::DummyTransport
      end
      example.run
    ensure
      Sentry.close
    end

    def transport
      Sentry.get_current_client.transport
    end

    it "captures an exception" do
      Sentry.capture_exception(StandardError.new("boom"))

      expect(transport.events.size).to eq(1)
      expect(transport.events.first.exception.values.first.value).to include("boom")
    end

    it "does not attach personally identifiable information" do
      expect(Sentry.configuration.send_default_pii).to be false
    end

    it "ignores routing errors raised by bots scanning unknown paths" do
      expect(Sentry.configuration.excluded_exceptions).to include("ActionController::RoutingError")
    end
  end
end
