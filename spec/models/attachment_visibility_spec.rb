require "rails_helper"

RSpec.describe AttachmentVisibility do
  describe ".visible?" do
    context "with a Band" do
      it "is visible to anyone when approved" do
        band = create(:band, :approved)

        expect(described_class.visible?(band, user: nil)).to be true
      end

      it "is not visible to a visitor when pending" do
        band = create(:band)

        expect(described_class.visible?(band, user: nil)).to be false
      end

      it "is visible to a band member even when pending" do
        band = create(:band)
        user = create(:user)
        create(:band_membership, band: band, user: user)

        expect(described_class.visible?(band, user: user)).to be true
      end
    end

    context "with an Album" do
      it "is visible to anyone when published and the band is approved" do
        band = create(:band, :approved)
        album = create(:album, :published, band: band)

        expect(described_class.visible?(album, user: nil)).to be true
      end

      it "enforces the album's early-access level" do
        band = create(:band, :approved)
        album = create(:album, :published, band: band, early_access_level: :supporter, early_access_until: 1.day.from_now)
        fan = create(:user)
        supporter = create(:user)
        core_member = create(:user)
        create(:membership, band: band, user: fan, level: :fan)
        create(:membership, band: band, user: supporter, level: :supporter)
        create(:membership, band: band, user: core_member, level: :core_member)

        expect(described_class.visible?(album, user: nil)).to be false
        expect(described_class.visible?(album, user: fan)).to be false
        expect(described_class.visible?(album, user: supporter)).to be true
        expect(described_class.visible?(album, user: core_member)).to be true
      end

      it "is not visible to a visitor when a draft" do
        band = create(:band, :approved)
        album = create(:album, band: band)

        expect(described_class.visible?(album, user: nil)).to be false
      end

      it "is visible to a band member even when a draft" do
        band = create(:band, :approved)
        album = create(:album, band: band)
        user = create(:user)
        create(:band_membership, band: band, user: user)

        expect(described_class.visible?(album, user: user)).to be true
      end
    end

    context "with a Post" do
      it "is visible to anyone when published and public visibility" do
        band = create(:band, :approved)
        post = create(:post, :published, band: band)

        expect(described_class.visible?(post, user: nil)).to be true
      end

      it "is not visible to a visitor when a draft" do
        band = create(:band, :approved)
        post = create(:post, band: band)

        expect(described_class.visible?(post, user: nil)).to be false
      end

      it "is not visible to an anonymous visitor when followers-only" do
        band = create(:band, :approved)
        post = create(:post, :published, :followers_only, band: band)

        expect(described_class.visible?(post, user: nil)).to be false
      end

      it "is not visible to a signed-in non-follower when followers-only" do
        band = create(:band, :approved)
        post = create(:post, :published, :followers_only, band: band)
        user = create(:user)

        expect(described_class.visible?(post, user: user)).to be false
      end

      it "is visible to a follower when followers-only" do
        band = create(:band, :approved)
        post = create(:post, :published, :followers_only, band: band)
        user = create(:user)
        create(:follow, band: band, user: user)

        expect(described_class.visible?(post, user: user)).to be true
      end

      it "is not visible to a follower without a membership when fan-only" do
        band = create(:band, :approved)
        post = create(:post, :published, :fan_only, band: band)
        user = create(:user)
        create(:follow, band: band, user: user)

        expect(described_class.visible?(post, user: user)).to be false
      end

      it "is visible to a user with an active Fan membership when fan-only" do
        band = create(:band, :approved)
        post = create(:post, :published, :fan_only, band: band)
        user = create(:user)
        create(:membership, band: band, user: user, level: :fan)

        expect(described_class.visible?(post, user: user)).to be true
      end

      it "is visible to a band member even when a draft" do
        band = create(:band, :approved)
        post = create(:post, band: band)
        user = create(:user)
        create(:band_membership, band: band, user: user)

        expect(described_class.visible?(post, user: user)).to be true
      end
    end

    context "with a Product" do
      it "is visible to anyone when published and the band is approved" do
        band = create(:band, :approved)
        product = create(:product, :published, band: band)

        expect(described_class.visible?(product, user: nil)).to be true
      end

      it "is not visible to a visitor when a draft" do
        band = create(:band, :approved)
        product = create(:product, band: band)

        expect(described_class.visible?(product, user: nil)).to be false
      end

      it "is visible to a band member even when a draft" do
        band = create(:band, :approved)
        product = create(:product, band: band)
        user = create(:user)
        create(:band_membership, band: band, user: user)

        expect(described_class.visible?(product, user: user)).to be true
      end
    end
  end
end
