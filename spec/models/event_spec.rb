require "rails_helper"

RSpec.describe Event, type: :model do
  it "is valid with valid attributes" do
    expect(build(:event)).to be_valid
  end

  it "requires a title" do
    event = build(:event, title: nil)

    expect(event).not_to be_valid
  end

  it "requires a location" do
    event = build(:event, location: nil)

    expect(event).not_to be_valid
  end

  it "requires a start time" do
    event = build(:event, starts_at: nil)

    expect(event).not_to be_valid
  end

  it "requires a band" do
    event = build(:event, band: nil)

    expect(event).not_to be_valid
  end

  it "defaults status to draft" do
    expect(create(:event).status).to eq("draft")
  end

  it "restricts status to draft or published" do
    event = build(:event)
    event.status = "archived"

    expect(event).not_to be_valid
  end

  it "accepts a blank ticket URL" do
    expect(build(:event, ticket_url: nil)).to be_valid
  end

  it "rejects an invalid ticket URL" do
    event = build(:event, ticket_url: "not a url")

    expect(event).not_to be_valid
    expect(event.errors[:ticket_url]).to be_present
  end

  describe "#ticket_link" do
    it "returns the URL when it is a valid http(s) link" do
      event = build(:event, ticket_url: "https://sympla.com.br/show")

      expect(event.ticket_link).to eq("https://sympla.com.br/show")
    end

    it "returns nil when the stored value is not a URL" do
      event = build(:event)
      event.ticket_url = "javascript:alert(1)"

      expect(event.ticket_link).to be_nil
    end
  end

  describe ".upcoming" do
    it "returns published-time-agnostic future events in chronological order" do
      band = create(:band)
      later = create(:event, band: band, starts_at: 2.weeks.from_now)
      sooner = create(:event, band: band, starts_at: 1.day.from_now)
      create(:event, :past, band: band)

      expect(band.events.upcoming).to eq([ sooner, later ])
    end
  end
end
