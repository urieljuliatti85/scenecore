require "rails_helper"

RSpec.describe BandAdminRequest, type: :model do
  it "is valid with a member's band_membership" do
    membership = create(:band_membership, role: :member)

    expect(build(:band_admin_request, band_membership: membership)).to be_valid
  end

  it "requires a band_membership" do
    expect(build(:band_admin_request, band_membership: nil)).not_to be_valid
  end

  it "is not valid for a band_membership that is already an administrator" do
    membership = create(:band_membership, :administrator)

    expect(build(:band_admin_request, band_membership: membership)).not_to be_valid
  end

  it "defaults status to pending" do
    expect(create(:band_admin_request).status).to eq("pending")
  end

  it "restricts status to pending, approved, rejected, or revoked" do
    band_admin_request = build(:band_admin_request)
    band_admin_request.status = "escalated"

    expect(band_admin_request).not_to be_valid
  end

  # The DB's partial unique index is what actually enforces this — bypass
  # model validations to prove the constraint holds on its own, not just
  # the (much easier to accidentally remove) validation layered on top.
  it "does not allow a second pending request for the same membership, even bypassing validations" do
    membership = create(:band_membership, role: :member)
    create(:band_admin_request, band_membership: membership)
    duplicate = build(:band_admin_request, band_membership: membership)

    expect { duplicate.save(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
  end

  it "allows a new pending request after a previous one was rejected" do
    membership = create(:band_membership, role: :member)
    create(:band_admin_request, :rejected, band_membership: membership)

    expect(build(:band_admin_request, band_membership: membership)).to be_valid
  end
end
