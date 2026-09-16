require "rails_helper"

RSpec.describe Membership, type: :model do
  it "is valid with valid attributes" do
    expect(build(:membership)).to be_valid
  end

  it "defaults level to fan and status to active" do
    membership = create(:membership)

    expect(membership.level).to eq("fan")
    expect(membership.status).to eq("active")
  end

  it "restricts level to fan, supporter or core_member" do
    membership = build(:membership)
    membership.level = "vip"

    expect(membership).not_to be_valid
  end

  it "restricts status to active, paused, cancelled or expired" do
    membership = build(:membership)
    membership.status = "trial"

    expect(membership).not_to be_valid
  end

  it "prevents the same user from having two memberships with the same band" do
    band = create(:band)
    user = create(:user)
    create(:membership, band: band, user: user)
    duplicate = build(:membership, band: band, user: user)

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:user_id]).to be_present
  end

  it "rejects a duplicate membership at the database level even if validation is bypassed" do
    band = create(:band)
    user = create(:user)
    create(:membership, band: band, user: user)
    duplicate = build(:membership, band: band, user: user)

    expect { duplicate.save(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
  end

  it "allows the same user to have different membership levels for different bands" do
    user = create(:user)
    band_a = create(:band)
    band_b = create(:band)
    create(:membership, :supporter, band: band_a, user: user)
    create(:membership, :core_member, band: band_b, user: user)

    expect(user.memberships.find_by(band: band_a).level).to eq("supporter")
    expect(user.memberships.find_by(band: band_b).level).to eq("core_member")
  end

  describe "#at_least?" do
    it "returns true when the membership level meets the minimum" do
      expect(build(:membership, :supporter).at_least?(:fan)).to be true
      expect(build(:membership, :supporter).at_least?(:supporter)).to be true
    end

    it "returns false when the membership level is below the minimum" do
      expect(build(:membership, :fan).at_least?(:supporter)).to be false
      expect(build(:membership, :supporter).at_least?(:core_member)).to be false
    end

    it "treats core_member as satisfying every lower level" do
      membership = build(:membership, :core_member)

      expect(membership.at_least?(:fan)).to be true
      expect(membership.at_least?(:supporter)).to be true
      expect(membership.at_least?(:core_member)).to be true
    end
  end

  describe "#grants_access?" do
    it "is true when active" do
      expect(build(:membership, status: :active)).to be_grants_access
    end

    %i[paused cancelled expired].each do |status|
      it "is false when #{status}" do
        expect(build(:membership, status: status)).not_to be_grants_access
      end
    end
  end

  describe "#can_access?" do
    it "requires both an active status and a sufficient level" do
      active_supporter = build(:membership, :supporter, status: :active)
      cancelled_supporter = build(:membership, :supporter, status: :cancelled)

      expect(active_supporter.can_access?(:fan)).to be true
      expect(cancelled_supporter.can_access?(:fan)).to be false
    end
  end

  describe "administrative separation" do
    it "does not grant band administration through a paid membership" do
      band = create(:band)
      user = create(:user)
      create(:membership, :core_member, band: band, user: user)

      expect(band.band_memberships.exists?(user_id: user.id)).to be false
    end

    it "does not grant paid membership benefits through band administration" do
      band = create(:band)
      user = create(:user)
      create(:band_membership, :administrator, band: band, user: user)

      expect(band.memberships.exists?(user_id: user.id)).to be false
    end
  end
end
