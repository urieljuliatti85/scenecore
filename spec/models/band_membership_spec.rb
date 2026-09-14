require "rails_helper"

RSpec.describe BandMembership, type: :model do
  it "is valid with valid attributes" do
    expect(build(:band_membership)).to be_valid
  end

  it "defaults role to member" do
    expect(create(:band_membership).role).to eq("member")
  end

  it "restricts role to member or administrator" do
    membership = build(:band_membership)
    membership.role = "owner"

    expect(membership).not_to be_valid
  end

  it "prevents the same user from joining the same band twice" do
    band = create(:band)
    user = create(:user)
    create(:band_membership, band: band, user: user)
    duplicate = build(:band_membership, band: band, user: user)

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:user_id]).to be_present
  end

  it "rejects a duplicate membership at the database level even if validation is bypassed" do
    band = create(:band)
    user = create(:user)
    create(:band_membership, band: band, user: user)
    duplicate = build(:band_membership, band: band, user: user)

    expect { duplicate.save(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
  end

  it "allows the same user to belong to multiple bands" do
    user = create(:user)
    band_a = create(:band)
    band_b = create(:band)
    create(:band_membership, band: band_a, user: user)
    create(:band_membership, band: band_b, user: user)

    expect(user.bands).to contain_exactly(band_a, band_b)
  end

  describe "last administrator protection" do
    it "prevents destroying the last administrator of a band" do
      band = create(:band)
      admin_membership = create(:band_membership, :administrator, band: band)

      result = admin_membership.destroy

      expect(result).to eq(false)
      expect(admin_membership.errors[:base]).to include("cannot remove the last administrator of a band")
      expect(band.band_memberships.reload).to include(admin_membership)
    end

    it "allows destroying an administrator when another administrator remains" do
      band = create(:band)
      admin_membership = create(:band_membership, :administrator, band: band)
      create(:band_membership, :administrator, band: band)

      expect(admin_membership.destroy).not_to eq(false)
    end

    it "prevents demoting the last administrator to member" do
      band = create(:band)
      admin_membership = create(:band_membership, :administrator, band: band)

      result = admin_membership.update(role: :member)

      expect(result).to eq(false)
      expect(admin_membership.errors[:base]).to include("cannot demote the last administrator of a band")
    end

    it "allows demoting an administrator when another administrator remains" do
      band = create(:band)
      admin_membership = create(:band_membership, :administrator, band: band)
      create(:band_membership, :administrator, band: band)

      expect(admin_membership.update(role: :member)).to eq(true)
    end

    it "allows destroying a plain member without restriction" do
      band = create(:band)
      create(:band_membership, :administrator, band: band)
      member_membership = create(:band_membership, band: band)

      expect(member_membership.destroy).not_to eq(false)
    end
  end
end
