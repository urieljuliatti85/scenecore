require "rails_helper"

RSpec.describe StripeWebhookEvent, type: :model do
  it "is valid with valid attributes" do
    expect(build(:stripe_webhook_event)).to be_valid
  end

  it "requires a stripe_event_id" do
    event = build(:stripe_webhook_event, stripe_event_id: nil)

    expect(event).not_to be_valid
  end

  it "requires a unique stripe_event_id" do
    create(:stripe_webhook_event, stripe_event_id: "evt_123")
    duplicate = build(:stripe_webhook_event, stripe_event_id: "evt_123")

    expect(duplicate).not_to be_valid
  end

  it "requires an event_type" do
    event = build(:stripe_webhook_event, event_type: nil)

    expect(event).not_to be_valid
  end

  describe ".record!" do
    it "creates a processed event record" do
      event = described_class.record!(stripe_event_id: "evt_abc", event_type: "checkout.session.completed")

      expect(event).to be_persisted
      expect(event.processed_at).to be_present
    end

    it "raises DuplicateEvent when the event was already recorded" do
      described_class.record!(stripe_event_id: "evt_abc", event_type: "checkout.session.completed")

      expect {
        described_class.record!(stripe_event_id: "evt_abc", event_type: "checkout.session.completed")
      }.to raise_error(StripeWebhookEvent::DuplicateEvent)
    end
  end
end
