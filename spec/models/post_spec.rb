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

  it "restricts visibility to public, followers, or subscribers" do
    post = build(:post)
    post.visibility = "everyone"

    expect(post).not_to be_valid
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
