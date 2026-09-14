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

  it "destroys its tracks when destroyed" do
    album = create(:album)
    track = create(:track, album: album)

    expect { album.destroy }.to change(Track, :count).by(-1)
    expect { track.reload }.to raise_error(ActiveRecord::RecordNotFound)
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
end
