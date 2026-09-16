require "rails_helper"

RSpec.describe Post, type: :model do
  it "is valid with valid attributes" do
    expect(build(:post)).to be_valid
  end

  it "requires a title" do
    post = build(:post, title: nil)

    expect(post).not_to be_valid
  end

  it "requires a band" do
    post = build(:post, band: nil)

    expect(post).not_to be_valid
  end

  it "defaults status to draft" do
    expect(create(:post).status).to eq("draft")
  end

  it "restricts status to draft or published" do
    post = build(:post)
    post.status = "archived"

    expect(post).not_to be_valid
  end

  it "defaults visibility to public" do
    expect(create(:post).visibility).to eq("public")
  end

  it "restricts visibility to public, followers, fan, supporter, or core_member" do
    post = build(:post)
    post.visibility = "everyone"

    expect(post).not_to be_valid
  end

  describe "#visible_to?" do
    it "is visible to anyone, including an anonymous visitor, when public" do
      post = build(:post, visibility: :public)

      expect(post.visible_to?(nil)).to be true
    end

    it "is not visible to an anonymous visitor when followers-only" do
      post = create(:post, :followers_only)

      expect(post.visible_to?(nil)).to be false
    end

    it "is visible to a follower when followers-only" do
      band = create(:band)
      post = create(:post, :followers_only, band: band)
      user = create(:user)
      create(:follow, band: band, user: user)

      expect(post.visible_to?(user)).to be true
    end

    it "is not visible to a non-follower without a membership when followers-only" do
      post = create(:post, :followers_only)
      user = create(:user)

      expect(post.visible_to?(user)).to be false
    end

    it "is visible to any active membership level when followers-only" do
      band = create(:band)
      post = create(:post, :followers_only, band: band)
      user = create(:user)
      create(:membership, band: band, user: user, level: :fan)

      expect(post.visible_to?(user)).to be true
    end

    it "is visible to a Fan when fan-only" do
      band = create(:band)
      post = create(:post, :fan_only, band: band)
      user = create(:user)
      create(:membership, band: band, user: user, level: :fan)

      expect(post.visible_to?(user)).to be true
    end

    it "is not visible to a Fan when supporter-only" do
      band = create(:band)
      post = create(:post, :supporter_only, band: band)
      user = create(:user)
      create(:membership, band: band, user: user, level: :fan)

      expect(post.visible_to?(user)).to be false
    end

    it "is visible to a Core Member when supporter-only (higher levels see lower-level content)" do
      band = create(:band)
      post = create(:post, :supporter_only, band: band)
      user = create(:user)
      create(:membership, band: band, user: user, level: :core_member)

      expect(post.visible_to?(user)).to be true
    end

    it "is not visible when the membership is paused" do
      band = create(:band)
      post = create(:post, :fan_only, band: band)
      user = create(:user)
      create(:membership, band: band, user: user, level: :fan, status: :paused)

      expect(post.visible_to?(user)).to be false
    end

    it "does not grant access based on another band's membership" do
      band = create(:band)
      other_band = create(:band)
      post = create(:post, :fan_only, band: band)
      user = create(:user)
      create(:membership, band: other_band, user: user, level: :core_member)

      expect(post.visible_to?(user)).to be false
    end
  end

  it "belongs to a band" do
    band = create(:band)
    post = create(:post, band: band)

    expect(post.band).to eq(band)
  end

  describe "image" do
    it "accepts a valid image" do
      post = build(:post)
      post.image.attach(
        io: File.open(Rails.root.join("spec/fixtures/files/band_photo.png")),
        filename: "band_photo.png",
        content_type: "image/png"
      )

      expect(post).to be_valid
    end

    it "rejects a non-image content type" do
      post = build(:post)
      post.image.attach(
        io: File.open(Rails.root.join("spec/fixtures/files/invalid_photo.txt")),
        filename: "invalid_photo.txt",
        content_type: "text/plain"
      )

      expect(post).not_to be_valid
      expect(post.errors[:image]).to be_present
    end

    it "rejects a file larger than the maximum size" do
      post = build(:post)
      post.image.attach(
        io: File.open(Rails.root.join("spec/fixtures/files/band_photo.png")),
        filename: "band_photo.png",
        content_type: "image/png"
      )
      allow(post.image).to receive(:byte_size).and_return(HasImage::IMAGE_MAX_SIZE + 1)

      expect(post).not_to be_valid
      expect(post.errors[:image]).to be_present
    end

    it "is valid without an image attached" do
      post = build(:post)

      expect(post.image).not_to be_attached
      expect(post).to be_valid
    end
  end
end
