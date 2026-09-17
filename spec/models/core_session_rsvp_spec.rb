require "rails_helper"

RSpec.describe CoreSessionRsvp, type: :model do
  it "is valid when the user has an active Core Member membership with the session's band" do
    band = create(:band)
    session = create(:core_session, band: band)
    user = create(:user)
    create(:membership, :core_member, band: band, user: user)

    expect(build(:core_session_rsvp, core_session: session, user: user)).to be_valid
  end

  it "is invalid when the user only has a Supporter membership with the session's band" do
    band = create(:band)
    session = create(:core_session, band: band)
    user = create(:user)
    create(:membership, :supporter, band: band, user: user)

    expect(build(:core_session_rsvp, core_session: session, user: user)).not_to be_valid
  end

  it "is invalid when the user has no membership with the session's band" do
    session = create(:core_session)
    user = create(:user)

    expect(build(:core_session_rsvp, core_session: session, user: user)).not_to be_valid
  end

  it "is invalid when the user's Core Member membership belongs to a different band" do
    band = create(:band)
    other_band = create(:band)
    session = create(:core_session, band: band)
    user = create(:user)
    create(:membership, :core_member, band: other_band, user: user)

    expect(build(:core_session_rsvp, core_session: session, user: user)).not_to be_valid
  end

  it "does not allow the same user to RSVP twice to the same session" do
    band = create(:band)
    session = create(:core_session, band: band)
    user = create(:user)
    create(:membership, :core_member, band: band, user: user)
    create(:core_session_rsvp, core_session: session, user: user)

    expect(build(:core_session_rsvp, core_session: session, user: user)).not_to be_valid
  end

  it "is invalid when the session is fully booked" do
    band = create(:band)
    session = create(:core_session, band: band, capacity: 1)
    attendee = create(:user)
    create(:membership, :core_member, band: band, user: attendee)
    create(:core_session_rsvp, core_session: session, user: attendee)

    latecomer = create(:user)
    create(:membership, :core_member, band: band, user: latecomer)

    expect(build(:core_session_rsvp, core_session: session, user: latecomer)).not_to be_valid
  end

  it "allows RSVPing to a different session with the same user" do
    band = create(:band)
    session = create(:core_session, band: band)
    other_session = create(:core_session, band: band)
    user = create(:user)
    create(:membership, :core_member, band: band, user: user)
    create(:core_session_rsvp, core_session: session, user: user)

    expect(build(:core_session_rsvp, core_session: other_session, user: user)).to be_valid
  end
end
