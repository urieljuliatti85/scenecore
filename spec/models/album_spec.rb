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
end
