require "rails_helper"

RSpec.describe "Authenticated blob access", type: :request do
  def attach_image(record, attribute)
    record.public_send(attribute).attach(
      io: File.open(Rails.root.join("spec/fixtures/files/band_photo.png")),
      filename: "band_photo.png",
      content_type: "image/png"
    )
    record.public_send(attribute)
  end

  describe "a band photo" do
    it "is reachable by anyone when the band is approved" do
      band = create(:band, :approved)
      image = attach_image(band, :photo)

      get rails_blob_path(image, only_path: true)

      expect(response).to have_http_status(:redirect)
    end

    it "is not reachable by a visitor when the band is pending" do
      band = create(:band)
      image = attach_image(band, :photo)

      get rails_blob_path(image, only_path: true)

      expect(response).to have_http_status(:not_found)
    end

    it "is reachable by a band member even when the band is pending" do
      band = create(:band)
      user = create(:user)
      create(:band_membership, band: band, user: user)
      image = attach_image(band, :photo)
      sign_in user

      get rails_blob_path(image, only_path: true)

      expect(response).to have_http_status(:redirect)
    end
  end

  describe "an album cover" do
    it "is not reachable by a visitor when the album is a draft" do
      band = create(:band, :approved)
      album = create(:album, band: band)
      image = attach_image(album, :cover)

      get rails_blob_path(image, only_path: true)

      expect(response).to have_http_status(:not_found)
    end

    it "is reachable by a band member even when the album is a draft" do
      band = create(:band, :approved)
      album = create(:album, band: band)
      user = create(:user)
      create(:band_membership, band: band, user: user)
      image = attach_image(album, :cover)
      sign_in user

      get rails_blob_path(image, only_path: true)

      expect(response).to have_http_status(:redirect)
    end
  end

  describe "a post image" do
    it "is reachable by anyone when the post is published and public" do
      band = create(:band, :approved)
      post_record = create(:post, :published, band: band)
      image = attach_image(post_record, :image)

      get rails_blob_path(image, only_path: true)

      expect(response).to have_http_status(:redirect)
    end

    it "is not reachable by a visitor when the post is a draft" do
      band = create(:band, :approved)
      post_record = create(:post, band: band)
      image = attach_image(post_record, :image)

      get rails_blob_path(image, only_path: true)

      expect(response).to have_http_status(:not_found)
    end

    it "is not reachable by an anonymous visitor when the post is followers-only" do
      band = create(:band, :approved)
      post_record = create(:post, :published, :followers_only, band: band)
      image = attach_image(post_record, :image)

      get rails_blob_path(image, only_path: true)

      expect(response).to have_http_status(:not_found)
    end

    it "is not reachable by a signed-in non-follower when the post is followers-only" do
      band = create(:band, :approved)
      post_record = create(:post, :published, :followers_only, band: band)
      image = attach_image(post_record, :image)
      user = create(:user)
      sign_in user

      get rails_blob_path(image, only_path: true)

      expect(response).to have_http_status(:not_found)
    end

    it "is reachable by a follower when the post is followers-only" do
      band = create(:band, :approved)
      post_record = create(:post, :published, :followers_only, band: band)
      image = attach_image(post_record, :image)
      user = create(:user)
      create(:follow, band: band, user: user)
      sign_in user

      get rails_blob_path(image, only_path: true)

      expect(response).to have_http_status(:redirect)
    end

    it "is not reachable by a non-member even when the post is published, subscribers-only" do
      band = create(:band, :approved)
      post_record = create(:post, :published, :subscribers_only, band: band)
      image = attach_image(post_record, :image)
      user = create(:user)
      create(:follow, band: band, user: user)
      sign_in user

      get rails_blob_path(image, only_path: true)

      expect(response).to have_http_status(:not_found)
    end

    it "is reachable by a band member even when the post is a draft" do
      band = create(:band, :approved)
      post_record = create(:post, band: band)
      user = create(:user)
      create(:band_membership, band: band, user: user)
      image = attach_image(post_record, :image)
      sign_in user

      get rails_blob_path(image, only_path: true)

      expect(response).to have_http_status(:redirect)
    end
  end
end
