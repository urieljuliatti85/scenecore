require "rails_helper"

RSpec.describe BandAdminRequest, type: :model do
  it "is valid with a user and a band" do
    expect(build(:band_admin_request)).to be_valid
  end

  it "requires a user" do
    expect(build(:band_admin_request, user: nil)).not_to be_valid
  end

  it "requires a band" do
    expect(build(:band_admin_request, band: nil)).not_to be_valid
  end

  it "is valid even when the user already holds a plain membership on the band" do
    band = create(:band)
    user = create(:user)
    create(:band_membership, band: band, user: user, role: :member)

    expect(build(:band_admin_request, user: user, band: band)).to be_valid
  end

  it "defaults status to pending" do
    expect(create(:band_admin_request).status).to eq("pending")
  end

  it "restricts status to pending, approved, rejected, or revoked" do
    band_admin_request = build(:band_admin_request)
    band_admin_request.status = "escalated"

    expect(band_admin_request).not_to be_valid
  end

  it "does not allow a second pending request from the same user for the same band" do
    band = create(:band)
    user = create(:user)
    create(:band_admin_request, user: user, band: band)

    duplicate = build(:band_admin_request, user: user, band: band)

    expect(duplicate).not_to be_valid
  end

  # The DB's partial unique index is what actually enforces this — bypass
  # model validations to prove the constraint holds on its own, not just
  # the (much easier to accidentally remove) validation layered on top.
  it "does not allow a second pending request, even bypassing validations" do
    band = create(:band)
    user = create(:user)
    create(:band_admin_request, user: user, band: band)
    duplicate = build(:band_admin_request, user: user, band: band)

    expect { duplicate.save(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
  end

  it "allows the same user to request a different band" do
    user = create(:user)
    create(:band_admin_request, user: user)

    expect(build(:band_admin_request, user: user)).to be_valid
  end

  it "allows a new pending request after a previous one was rejected" do
    band = create(:band)
    user = create(:user)
    create(:band_admin_request, :rejected, user: user, band: band)

    expect(build(:band_admin_request, user: user, band: band)).to be_valid
  end
end
