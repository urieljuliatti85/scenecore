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

  it "defaults post_type to announcement" do
    expect(create(:post).post_type).to eq("announcement")
  end

  it "restricts post_type to the supported membership content types" do
    post = build(:post)
    post.post_type = "interview"

    expect(post).not_to be_valid
  end

  it "accepts rehearsal_recording as a post_type" do
    expect(build(:post, post_type: :rehearsal_recording)).to be_valid
  end

  it "accepts production journals, exclusive streams, and rare archives" do
    expect(build(:post, post_type: :production_journal)).to be_valid
    expect(build(:post, post_type: :exclusive_stream)).to be_valid
    expect(build(:post, post_type: :rare_archive)).to be_valid
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

  describe "#required_level" do
    it "is nil when the post is public" do
      expect(build(:post, visibility: :public).required_level).to be_nil
    end

    it "is nil when the post is followers-only, since that is not a paid level" do
      expect(build(:post, :followers_only).required_level).to be_nil
    end

    it "returns the membership level for a level-gated post" do
      expect(build(:post, :supporter_only).required_level).to eq("supporter")
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

  describe "attachments" do
    it "accepts a valid attachment" do
      post = build(:post)
      post.attachments.attach(
        io: File.open(Rails.root.join("spec/fixtures/files/demo.pdf")),
        filename: "demo.pdf",
        content_type: "application/pdf"
      )

      expect(post).to be_valid
    end

    it "rejects a disallowed content type" do
      post = build(:post)
      post.attachments.attach(
        io: File.open(Rails.root.join("spec/fixtures/files/invalid_photo.txt")),
        filename: "invalid_photo.txt",
        content_type: "text/plain"
      )

      expect(post).not_to be_valid
      expect(post.errors[:attachments]).to be_present
    end

    it "rejects a file larger than the maximum size" do
      post = build(:post)
      post.attachments.attach(
        io: File.open(Rails.root.join("spec/fixtures/files/demo.pdf")),
        filename: "demo.pdf",
        content_type: "application/pdf"
      )
      allow(post.attachments.first).to receive(:byte_size).and_return(HasAttachments::ATTACHMENT_MAX_SIZE + 1)

      expect(post).not_to be_valid
      expect(post.errors[:attachments]).to be_present
    end

    it "is valid without any attachments" do
      post = build(:post)

      expect(post.attachments).not_to be_attached
      expect(post).to be_valid
    end

    it "accepts multiple attachments" do
      post = build(:post)
      post.attachments.attach(
        io: File.open(Rails.root.join("spec/fixtures/files/demo.pdf")),
        filename: "lyrics.pdf",
        content_type: "application/pdf"
      )
      post.attachments.attach(
        io: File.open(Rails.root.join("spec/fixtures/files/demo.pdf")),
        filename: "notes.pdf",
        content_type: "application/pdf"
      )

      expect(post).to be_valid
      expect(post.attachments.count).to eq(2)
    end
  end

  describe "early access" do
    it "requires an until date when a level is set" do
      expect(build(:post, early_access_level: :supporter, early_access_until: nil)).not_to be_valid
    end

    it "requires a level when an until date is set" do
      expect(build(:post, early_access_level: nil, early_access_until: 1.day.from_now)).not_to be_valid
    end

    it "is valid with neither set" do
      expect(build(:post, early_access_level: nil, early_access_until: nil)).to be_valid
    end

    it "is valid with both set to a known level" do
      expect(build(:post, early_access_level: :supporter, early_access_until: 1.day.from_now)).to be_valid
    end
  end

  describe "#in_early_access?" do
    it "is false when no early access is configured" do
      expect(build(:post)).not_to be_in_early_access
    end

    it "is true while the until date is in the future" do
      expect(build(:post, early_access_level: :supporter, early_access_until: 1.day.from_now)).to be_in_early_access
    end

    it "is false once the until date has passed" do
      expect(build(:post, early_access_level: :supporter, early_access_until: 1.day.ago)).not_to be_in_early_access
    end
  end

  describe "#visible_to? with early access" do
    let(:band) { create(:band) }

    it "is not visible to an anonymous visitor during early access, even on an otherwise public post" do
      post = create(:post, band: band, visibility: :public, early_access_level: :supporter, early_access_until: 1.day.from_now)

      expect(post.visible_to?(nil)).to be false
    end

    it "is not visible to a user below the required early access level" do
      post = create(:post, band: band, visibility: :public, early_access_level: :supporter, early_access_until: 1.day.from_now)
      fan = create(:user)
      create(:membership, band: band, user: fan, level: :fan)

      expect(post.visible_to?(fan)).to be false
    end

    it "is visible to a user who meets the required early access level" do
      post = create(:post, band: band, visibility: :public, early_access_level: :supporter, early_access_until: 1.day.from_now)
      supporter = create(:user)
      create(:membership, band: band, user: supporter, level: :supporter)

      expect(post.visible_to?(supporter)).to be true
    end

    it "grants early access to a Core Member on a post gated at a lower level" do
      post = create(:post, band: band, visibility: :fan, early_access_level: :core_member, early_access_until: 1.day.from_now)
      core_member = create(:user)
      create(:membership, band: band, user: core_member, level: :core_member)

      expect(post.visible_to?(core_member)).to be true
    end

    it "falls back to ordinary visibility once the early access window has passed" do
      post = create(:post, band: band, visibility: :public, early_access_level: :supporter, early_access_until: 1.day.ago)

      expect(post.visible_to?(nil)).to be true
    end

    it "still enforces ordinary visibility once the window has passed even if it's more restrictive" do
      post = create(:post, band: band, visibility: :core_member, early_access_level: :supporter, early_access_until: 1.day.ago)
      fan = create(:user)
      create(:membership, band: band, user: fan, level: :fan)

      expect(post.visible_to?(fan)).to be false
    end
  end

  describe "#required_level with early access" do
    it "returns the early access level while the window is open, even over a lower ordinary visibility" do
      post = build(:post, visibility: :public, early_access_level: :supporter, early_access_until: 1.day.from_now)

      expect(post.required_level).to eq("supporter")
    end

    it "falls back to ordinary required_level once the window has passed" do
      post = build(:post, :supporter_only, early_access_level: :fan, early_access_until: 1.day.ago)

      expect(post.required_level).to eq("supporter")
    end
  end
end
