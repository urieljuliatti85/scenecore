require "rails_helper"

RSpec.describe Band, type: :model do
  it "is valid with valid attributes" do
    expect(build(:band)).to be_valid
  end

  it "requires a name" do
    band = build(:band, name: nil)

    expect(band).not_to be_valid
  end

  it "generates a slug from the name on create" do
    band = create(:band, name: "The Testers")

    expect(band.slug).to eq("the-testers")
  end

  it "generates a unique slug when names collide" do
    create(:band, name: "The Testers")
    other = create(:band, name: "The Testers")

    expect(other.slug).to eq("the-testers-2")
  end

  it "rejects a duplicate slug at the database level even if validation is bypassed" do
    create(:band, name: "The Testers")
    duplicate = build(:band, name: "Other name")
    duplicate.slug = "the-testers"

    expect { duplicate.save(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
  end

  it "defaults status to pending" do
    expect(create(:band).status).to eq("pending")
  end

  it "restricts status to pending, approved, or rejected" do
    band = build(:band)
    band.status = "suspended"

    expect(band).not_to be_valid
  end

  it "has many members through band memberships" do
    band = create(:band)
    user = create(:user)
    create(:band_membership, band: band, user: user)

    expect(band.members).to contain_exactly(user)
  end

  describe "photo" do
    it "accepts a valid image" do
      band = build(:band)
      band.photo.attach(
        io: File.open(Rails.root.join("spec/fixtures/files/band_photo.png")),
        filename: "band_photo.png",
        content_type: "image/png"
      )

      expect(band).to be_valid
    end

    it "rejects a non-image content type" do
      band = build(:band)
      band.photo.attach(
        io: File.open(Rails.root.join("spec/fixtures/files/invalid_photo.txt")),
        filename: "invalid_photo.txt",
        content_type: "text/plain"
      )

      expect(band).not_to be_valid
      expect(band.errors[:photo]).to be_present
    end

    it "rejects a file larger than the maximum size" do
      band = build(:band)
      band.photo.attach(
        io: File.open(Rails.root.join("spec/fixtures/files/band_photo.png")),
        filename: "band_photo.png",
        content_type: "image/png"
      )
      allow(band.photo).to receive(:byte_size).and_return(Band::PHOTO_MAX_SIZE + 1)

      expect(band).not_to be_valid
      expect(band.errors[:photo]).to be_present
    end

    it "is valid without a photo attached" do
      band = build(:band)

      expect(band.photo).not_to be_attached
      expect(band).to be_valid
    end
  end

  describe "social links" do
    %i[spotify_url youtube_url instagram_url website_url].each do |attribute|
      it "accepts a blank #{attribute}" do
        band = build(:band, attribute => nil)

        expect(band).to be_valid
      end

      it "accepts a valid http(s) URL for #{attribute}" do
        band = build(:band, attribute => "https://example.com/band")

        expect(band).to be_valid
      end

      it "rejects an invalid #{attribute}" do
        band = build(:band, attribute => "not a url")

        expect(band).not_to be_valid
        expect(band.errors[attribute]).to be_present
      end
    end
  end

  describe "#social_links" do
    it "only includes attributes that are present" do
      band = build(:band, spotify_url: "https://open.spotify.com/artist/1",
                           youtube_url: nil,
                           instagram_url: "https://instagram.com/band",
                           website_url: nil)

      expect(band.social_links).to eq(
        spotify_url: "https://open.spotify.com/artist/1",
        instagram_url: "https://instagram.com/band"
      )
    end

    it "is empty when no social links are set" do
      band = build(:band)

      expect(band.social_links).to be_empty
    end
  end

  describe ".featured" do
    it "returns the most recently approved band" do
      create(:band, :approved, name: "Older")
      newer = create(:band, :approved, name: "Newer")

      expect(Band.featured).to contain_exactly(newer)
    end

    it "excludes pending and rejected bands" do
      create(:band, name: "Pending")
      create(:band, :rejected, name: "Rejected")

      expect(Band.featured).to be_empty
    end
  end
end
