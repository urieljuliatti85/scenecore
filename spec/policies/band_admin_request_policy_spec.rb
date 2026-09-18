require "rails_helper"

RSpec.describe BandAdminRequestPolicy do
  describe "#create?" do
    it "is true for the member requesting their own promotion" do
      membership = create(:band_membership, role: :member)
      band_admin_request = build(:band_admin_request, band_membership: membership)

      expect(described_class.new(membership.user, band_admin_request).create?).to be true
    end

    it "is false for a different user" do
      membership = create(:band_membership, role: :member)
      band_admin_request = build(:band_admin_request, band_membership: membership)
      other_user = create(:user)

      expect(described_class.new(other_user, band_admin_request).create?).to be false
    end

    it "is false when the membership is already an administrator" do
      membership = create(:band_membership, :administrator)
      band_admin_request = build(:band_admin_request, band_membership: membership)

      expect(described_class.new(membership.user, band_admin_request).create?).to be false
    end

    it "is false for an anonymous visitor" do
      membership = create(:band_membership, role: :member)
      band_admin_request = build(:band_admin_request, band_membership: membership)

      expect(described_class.new(nil, band_admin_request).create?).to be false
    end
  end

  describe "#revoke?" do
    it "is true for the requester" do
      membership = create(:band_membership, role: :member)
      band_admin_request = create(:band_admin_request, band_membership: membership)

      expect(described_class.new(membership.user, band_admin_request).revoke?).to be true
    end

    it "is true for a platform administrator" do
      membership = create(:band_membership, role: :member)
      band_admin_request = create(:band_admin_request, band_membership: membership)
      platform_admin = create(:user, :platform_admin)

      expect(described_class.new(platform_admin, band_admin_request).revoke?).to be true
    end

    it "is false for another band member" do
      membership = create(:band_membership, role: :member)
      band_admin_request = create(:band_admin_request, band_membership: membership)
      other_user = create(:user)

      expect(described_class.new(other_user, band_admin_request).revoke?).to be false
    end
  end

  describe "#approve?" do
    it "is true for a platform administrator" do
      band_admin_request = create(:band_admin_request)
      platform_admin = create(:user, :platform_admin)

      expect(described_class.new(platform_admin, band_admin_request).approve?).to be true
    end

    it "is false for the requester themselves" do
      membership = create(:band_membership, role: :member)
      band_admin_request = create(:band_admin_request, band_membership: membership)

      expect(described_class.new(membership.user, band_admin_request).approve?).to be false
    end

    it "is false for an anonymous visitor" do
      band_admin_request = create(:band_admin_request)

      expect(described_class.new(nil, band_admin_request).approve?).to be false
    end
  end

  describe "#reject?" do
    it "is true for a platform administrator" do
      band_admin_request = create(:band_admin_request)
      platform_admin = create(:user, :platform_admin)

      expect(described_class.new(platform_admin, band_admin_request).reject?).to be true
    end

    it "is false for the requester themselves" do
      membership = create(:band_membership, role: :member)
      band_admin_request = create(:band_admin_request, band_membership: membership)

      expect(described_class.new(membership.user, band_admin_request).reject?).to be false
    end
  end
end
