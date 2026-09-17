require "rails_helper"

RSpec.describe Album, type: :model do
  it "is valid with valid attributes" do
    expect(build(:album)).to be_valid
  end

  it "requires a title" do
    album = build(:album, title: nil)

    expect(album).not_to be_valid
  end

  it "requires a band" do
    album = build(:album, band: nil)

    expect(album).not_to be_valid
  end

  it "defaults status to draft" do
    expect(create(:album).status).to eq("draft")
  end

  it "restricts status to draft or published" do
    album = build(:album)
    album.status = "archived"

    expect(album).not_to be_valid
  end

  it "belongs to a band" do
    band = create(:band)
    album = create(:album, band: band)

    expect(album.band).to eq(band)
  end

  describe "#spotify_url" do
    it "derives the album link from the imported Spotify id" do
      album = build(:album, spotify_id: "4aawyAB9vmqN3uQ7FjRGTy")

      expect(album.spotify_url).to eq("https://open.spotify.com/album/4aawyAB9vmqN3uQ7FjRGTy")
    end

    it "is nil for an album that was not imported from Spotify" do
      expect(build(:album, spotify_id: nil).spotify_url).to be_nil
    end

    # The value goes straight into an href, so a row written outside the
    # model's validation (console, fixture, a future import path) must not
    # be able to put a hostile scheme or another host in front of a visitor.
    it "refuses anything that is not a Spotify id" do
      hostile = [
        "javascript:alert(1)",
        "https://evil.com/x",
        "' onmouseover='alert(1)",
        "../../etc/passwd",
        "4aawyAB9vmqN3uQ7FjRGT"
      ]

      hostile.each do |value|
        expect(build(:album, spotify_id: value).spotify_url).to be_nil
      end
    end

    it "rejects a malformed Spotify id on save" do
      album = build(:album, spotify_id: "javascript:alert(1)")

      expect(album).not_to be_valid
      expect(album.errors[:spotify_id]).to be_present
    end
  end

  describe "#bandcamp_embed_link" do
    it "returns a valid Bandcamp embed player URL" do
      url = "https://bandcamp.com/EmbeddedPlayer/album=1234567890/size=large/bgcol=333333/linkcol=0f91ff/artwork=small/transparent=true/"
      album = build(:album, bandcamp_embed_url: url)

      expect(album.bandcamp_embed_link).to eq(url)
    end

    it "is nil for an album with no Bandcamp embed URL" do
      expect(build(:album, bandcamp_embed_url: nil).bandcamp_embed_link).to be_nil
    end

    # The value goes straight into an iframe src, so a row written outside
    # the model's validation must not be able to put a hostile scheme or
    # another host in front of a visitor.
    it "refuses anything that is not a bandcamp.com/EmbeddedPlayer URL" do
      hostile = [
        "javascript:alert(1)",
        "https://evil.com/EmbeddedPlayer/album=123",
        "https://bandcamp.com.evil.com/EmbeddedPlayer/album=123",
        "http://bandcamp.com/EmbeddedPlayer/album=123",
        "https://bandcamp.com/album/foo"
      ]

      hostile.each do |value|
        expect(build(:album, bandcamp_embed_url: value).bandcamp_embed_link).to be_nil
      end
    end

    it "rejects a malformed Bandcamp embed URL on save" do
      album = build(:album, bandcamp_embed_url: "javascript:alert(1)")

      expect(album).not_to be_valid
      expect(album.errors[:bandcamp_embed_url]).to be_present
    end

    it "is valid without a Bandcamp embed URL" do
      expect(build(:album, bandcamp_embed_url: nil)).to be_valid
    end
  end

  it "destroys its admin action logs when destroyed" do
    album = create(:album)
    create(:admin_action_log, subject: album)

    expect { album.destroy }.to change(AdminActionLog, :count).by(-1)
  end

  describe "cover" do
    it "accepts a valid image" do
      album = build(:album)
      album.cover.attach(
        io: File.open(Rails.root.join("spec/fixtures/files/band_photo.png")),
        filename: "cover.png",
        content_type: "image/png"
      )

      expect(album).to be_valid
    end

    it "rejects a non-image content type" do
      album = build(:album)
      album.cover.attach(
        io: File.open(Rails.root.join("spec/fixtures/files/invalid_photo.txt")),
        filename: "invalid_photo.txt",
        content_type: "text/plain"
      )

      expect(album).not_to be_valid
      expect(album.errors[:cover]).to be_present
    end

    it "rejects a file larger than the maximum size" do
      album = build(:album)
      album.cover.attach(
        io: File.open(Rails.root.join("spec/fixtures/files/band_photo.png")),
        filename: "cover.png",
        content_type: "image/png"
      )
      allow(album.cover).to receive(:byte_size).and_return(HasImage::IMAGE_MAX_SIZE + 1)

      expect(album).not_to be_valid
      expect(album.errors[:cover]).to be_present
    end

    it "is valid without a cover attached" do
      album = build(:album)

      expect(album.cover).not_to be_attached
      expect(album).to be_valid
    end
  end

  describe "#cover_url" do
    it "returns nil when there is no uploaded cover or Spotify cover" do
      album = build(:album, spotify_cover_url: nil)

      expect(album.cover_url).to be_nil
    end

    it "returns the Spotify cover URL when there is no uploaded cover" do
      album = build(:album, spotify_cover_url: "https://i.scdn.co/image/abc123.jpg")

      expect(album.cover_url).to eq("https://i.scdn.co/image/abc123.jpg")
    end

    it "prefers the uploaded cover over the Spotify cover URL" do
      album = create(:album, spotify_cover_url: "https://i.scdn.co/image/abc123.jpg")
      album.cover.attach(
        io: File.open(Rails.root.join("spec/fixtures/files/band_photo.png")),
        filename: "cover.png",
        content_type: "image/png"
      )

      expect(album.cover_url).to include("active_storage")
    end
  end

  describe "early access" do
    it "requires an until date when a level is set" do
      album = build(:album, early_access_level: :supporter, early_access_until: nil)

      expect(album).not_to be_valid
    end

    it "requires a level when an until date is set" do
      album = build(:album, early_access_level: nil, early_access_until: 1.day.from_now)

      expect(album).not_to be_valid
    end

    it "is valid with neither set" do
      album = build(:album, early_access_level: nil, early_access_until: nil)

      expect(album).to be_valid
    end

    it "is valid with both set to a known level" do
      album = build(:album, early_access_level: :supporter, early_access_until: 1.day.from_now)

      expect(album).to be_valid
    end
  end

  describe "#in_early_access?" do
    it "is false when no early access is configured" do
      album = build(:album, early_access_level: nil, early_access_until: nil)

      expect(album).not_to be_in_early_access
    end

    it "is true while the until date is in the future" do
      album = build(:album, early_access_level: :supporter, early_access_until: 1.day.from_now)

      expect(album).to be_in_early_access
    end

    it "is false once the until date has passed" do
      album = build(:album, early_access_level: :supporter, early_access_until: 1.day.ago)

      expect(album).not_to be_in_early_access
    end
  end

  describe "#visible_to?" do
    let(:band) { create(:band) }

    it "is visible to anyone when not in early access" do
      album = create(:album, band: band, early_access_level: nil, early_access_until: nil)

      expect(album.visible_to?(nil)).to be true
    end

    it "is not visible to an anonymous visitor during early access" do
      album = create(:album, band: band, early_access_level: :supporter, early_access_until: 1.day.from_now)

      expect(album.visible_to?(nil)).to be false
    end

    it "is not visible to a user without the required membership level" do
      album = create(:album, band: band, early_access_level: :supporter, early_access_until: 1.day.from_now)
      fan = create(:user)
      create(:membership, band: band, user: fan, level: :fan)

      expect(album.visible_to?(fan)).to be false
    end

    it "is visible to a user who meets the required membership level" do
      album = create(:album, band: band, early_access_level: :supporter, early_access_until: 1.day.from_now)
      supporter = create(:user)
      create(:membership, band: band, user: supporter, level: :supporter)

      expect(album.visible_to?(supporter)).to be true
    end

    it "is visible to a user above the required membership level" do
      album = create(:album, band: band, early_access_level: :supporter, early_access_until: 1.day.from_now)
      core_member = create(:user)
      create(:membership, band: band, user: core_member, level: :core_member)

      expect(album.visible_to?(core_member)).to be true
    end

    it "is not visible to a user with the level but a paused membership" do
      album = create(:album, band: band, early_access_level: :supporter, early_access_until: 1.day.from_now)
      supporter = create(:user)
      create(:membership, :paused, band: band, user: supporter, level: :supporter)

      expect(album.visible_to?(supporter)).to be false
    end

    it "is visible to everyone once the early access window has passed" do
      album = create(:album, band: band, early_access_level: :supporter, early_access_until: 1.day.ago)

      expect(album.visible_to?(nil)).to be true
    end
  end

  describe "#required_level" do
    it "is nil when no early access is configured" do
      expect(build(:album).required_level).to be_nil
    end

    it "is nil once the early access window has passed" do
      album = build(:album, early_access_level: :supporter, early_access_until: 1.day.ago)

      expect(album.required_level).to be_nil
    end

    it "returns the early access level while the window is still open" do
      album = build(:album, early_access_level: :supporter, early_access_until: 1.day.from_now)

      expect(album.required_level).to eq("supporter")
    end
  end
end
