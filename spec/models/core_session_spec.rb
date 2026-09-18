require "rails_helper"

RSpec.describe CoreSession, type: :model do
  it "is valid with valid attributes" do
    expect(build(:core_session)).to be_valid
  end

  it "requires a title" do
    expect(build(:core_session, title: nil)).not_to be_valid
  end

  it "requires a starts_at" do
    expect(build(:core_session, starts_at: nil)).not_to be_valid
  end

  it "restricts session_type to the known types" do
    session = build(:core_session)
    session.session_type = "campfire"

    expect(session).not_to be_valid
  end

  it "rejects a capacity of zero or less" do
    expect(build(:core_session, capacity: 0)).not_to be_valid
  end

  it "allows a nil capacity for no limit" do
    expect(build(:core_session, capacity: nil)).to be_valid
  end

  it "defaults its audience to Core Member" do
    expect(build(:core_session).audience_level).to eq("core_member")
  end

  it "limits private sessions to Supporter or Core Member audiences" do
    session = build(:core_session)
    session.audience_level = "fan"

    expect(session).not_to be_valid
  end

  it "accepts a valid external access link" do
    expect(build(:core_session, access_url: "https://meet.example.com/session")).to be_valid
  end

  describe "#seats_available?" do
    it "is true when capacity is nil" do
      session = create(:core_session, capacity: nil)

      expect(session.seats_available?).to be true
    end

    it "is true when RSVPs are below capacity" do
      band = create(:band)
      session = create(:core_session, band: band, capacity: 2)
      attendee = create(:user)
      create(:membership, :core_member, band: band, user: attendee)
      create(:core_session_rsvp, core_session: session, user: attendee)

      expect(session.seats_available?).to be true
    end

    it "is false when RSVPs have reached capacity" do
      band = create(:band)
      session = create(:core_session, band: band, capacity: 1)
      attendee = create(:user)
      create(:membership, :core_member, band: band, user: attendee)
      create(:core_session_rsvp, core_session: session, user: attendee)

      expect(session.seats_available?).to be false
    end
  end

  describe "#spots_remaining" do
    it "is nil when capacity is nil" do
      session = create(:core_session, capacity: nil)

      expect(session.spots_remaining).to be_nil
    end

    it "counts down as RSVPs come in" do
      band = create(:band)
      session = create(:core_session, band: band, capacity: 3)
      attendee = create(:user)
      create(:membership, :core_member, band: band, user: attendee)
      create(:core_session_rsvp, core_session: session, user: attendee)

      expect(session.spots_remaining).to eq(2)
    end

    it "is zero once capacity is reached" do
      band = create(:band)
      session = create(:core_session, band: band, capacity: 1)
      attendee = create(:user)
      create(:membership, :core_member, band: band, user: attendee)
      create(:core_session_rsvp, core_session: session, user: attendee)

      expect(session.spots_remaining).to eq(0)
    end
  end

  describe "#visible_to?" do
    it "is true for a Core Member of the band" do
      band = create(:band)
      session = create(:core_session, band: band)
      user = create(:user)
      create(:membership, :core_member, band: band, user: user)

      expect(session.visible_to?(user)).to be true
    end

    it "is false for a Supporter of the band" do
      band = create(:band)
      session = create(:core_session, band: band)
      user = create(:user)
      create(:membership, :supporter, band: band, user: user)

      expect(session.visible_to?(user)).to be false
    end

    it "is true for a Supporter and Core Member when the audience starts at Supporter" do
      band = create(:band)
      session = create(:core_session, band: band, audience_level: :supporter)
      supporter = create(:user)
      core_member = create(:user)
      create(:membership, :supporter, band: band, user: supporter)
      create(:membership, :core_member, band: band, user: core_member)

      expect(session.visible_to?(supporter)).to be true
      expect(session.visible_to?(core_member)).to be true
    end

    it "is false for a user with no membership" do
      session = create(:core_session)
      user = create(:user)

      expect(session.visible_to?(user)).to be false
    end

    it "is false for an anonymous visitor" do
      session = create(:core_session)

      expect(session.visible_to?(nil)).to be false
    end
  end

  describe "#rsvpable_by?" do
    it "is true for a Core Member when the session is published and has seats" do
      band = create(:band)
      session = create(:core_session, :published, band: band, capacity: 2)
      user = create(:user)
      create(:membership, :core_member, band: band, user: user)

      expect(session.rsvpable_by?(user)).to be true
    end

    it "is false when the session is a draft" do
      band = create(:band)
      session = create(:core_session, band: band)
      user = create(:user)
      create(:membership, :core_member, band: band, user: user)

      expect(session.rsvpable_by?(user)).to be false
    end

    it "is false when the session is fully booked" do
      band = create(:band)
      session = create(:core_session, :published, band: band, capacity: 1)
      attendee = create(:user)
      create(:membership, :core_member, band: band, user: attendee)
      create(:core_session_rsvp, core_session: session, user: attendee)
      user = create(:user)
      create(:membership, :core_member, band: band, user: user)

      expect(session.rsvpable_by?(user)).to be false
    end
  end

  describe "#rsvped_by?" do
    it "is true when the user has an RSVP" do
      band = create(:band)
      session = create(:core_session, band: band)
      user = create(:user)
      create(:membership, :core_member, band: band, user: user)
      create(:core_session_rsvp, core_session: session, user: user)

      expect(session.rsvped_by?(user)).to be true
    end

    it "is false when the user has no RSVP" do
      session = create(:core_session)
      user = create(:user)

      expect(session.rsvped_by?(user)).to be false
    end
  end
end
