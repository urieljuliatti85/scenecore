require "rails_helper"

RSpec.describe BandAdminRequestPolicy do
  describe "#create?" do
    it "is true for the user requesting for themselves" do
      user = create(:user)
      band_admin_request = build(:band_admin_request, user: user)

      expect(described_class.new(user, band_admin_request).create?).to be true
    end

    it "is true even when the user has no existing membership on the band" do
      band = create(:band)
      user = create(:user)
      band_admin_request = build(:band_admin_request, user: user, band: band)

      expect(described_class.new(user, band_admin_request).create?).to be true
    end

    it "is false for a different user" do
      band_admin_request = build(:band_admin_request)
      other_user = create(:user)

      expect(described_class.new(other_user, band_admin_request).create?).to be false
    end

    it "is false for an anonymous visitor" do
      band_admin_request = build(:band_admin_request)

      expect(described_class.new(nil, band_admin_request).create?).to be false
    end
  end

  describe "#revoke?" do
    it "is true for the requester" do
      band_admin_request = create(:band_admin_request)

      expect(described_class.new(band_admin_request.user, band_admin_request).revoke?).to be true
    end

    it "is true for a platform administrator" do
      band_admin_request = create(:band_admin_request)
      platform_admin = create(:user, :platform_admin)

      expect(described_class.new(platform_admin, band_admin_request).revoke?).to be true
    end

    it "is false for another user" do
      band_admin_request = create(:band_admin_request)
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
      band_admin_request = create(:band_admin_request)

      expect(described_class.new(band_admin_request.user, band_admin_request).approve?).to be false
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
      band_admin_request = create(:band_admin_request)

      expect(described_class.new(band_admin_request.user, band_admin_request).reject?).to be false
    end
  end
end
