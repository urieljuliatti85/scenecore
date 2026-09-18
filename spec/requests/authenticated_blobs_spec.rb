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

    it "blocks a Fan from an early-release cover reserved for Supporters" do
      band = create(:band, :approved)
      album = create(:album, :published, band: band, early_access_level: :supporter, early_access_until: 1.day.from_now)
      image = attach_image(album, :cover)
      fan = create(:user)
      create(:membership, band: band, user: fan, level: :fan)
      sign_in fan

      get rails_blob_path(image, only_path: true)

      expect(response).to have_http_status(:not_found)
    end

    it "allows a Supporter and Core Member to access a Supporter early-release cover" do
      band = create(:band, :approved)
      album = create(:album, :published, band: band, early_access_level: :supporter, early_access_until: 1.day.from_now)
      image = attach_image(album, :cover)

      [ :supporter, :core_member ].each do |level|
        user = create(:user)
        create(:membership, band: band, user: user, level: level)
        sign_in user

        get rails_blob_path(image, only_path: true)

        expect(response).to have_http_status(:redirect)
        sign_out user
      end
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

    it "is not reachable by a follower without a membership when the post is fan-only" do
      band = create(:band, :approved)
      post_record = create(:post, :published, :fan_only, band: band)
      image = attach_image(post_record, :image)
      user = create(:user)
      create(:follow, band: band, user: user)
      sign_in user

      get rails_blob_path(image, only_path: true)

      expect(response).to have_http_status(:not_found)
    end

    it "is reachable by a user with an active Fan membership when the post is fan-only" do
      band = create(:band, :approved)
      post_record = create(:post, :published, :fan_only, band: band)
      image = attach_image(post_record, :image)
      user = create(:user)
      create(:membership, band: band, user: user, level: :fan)
      sign_in user

      get rails_blob_path(image, only_path: true)

      expect(response).to have_http_status(:redirect)
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

  describe "a priority product image" do
    it "is not reachable by a Fan before the product opens to Supporters" do
      band = create(:band, :approved)
      product = create(:product, :published, band: band, early_access_level: :supporter, early_access_until: 1.day.from_now)
      image = attach_image(product, :image)
      fan = create(:user)
      create(:membership, band: band, user: fan, level: :fan)
      sign_in fan

      get rails_blob_path(image, only_path: true)

      expect(response).to have_http_status(:not_found)
    end

    it "is reachable by a Core Member during a Supporter priority window" do
      band = create(:band, :approved)
      product = create(:product, :published, band: band, early_access_level: :supporter, early_access_until: 1.day.from_now)
      image = attach_image(product, :image)
      core_member = create(:user)
      create(:membership, :core_member, band: band, user: core_member)
      sign_in core_member

      get rails_blob_path(image, only_path: true)

      expect(response).to have_http_status(:redirect)
    end
  end

  describe "a post's composition journal attachment" do
    def attach_pdf(record)
      record.attachments.attach(
        io: File.open(Rails.root.join("spec/fixtures/files/demo.pdf")),
        filename: "demo.pdf",
        content_type: "application/pdf"
      )
      record.attachments.first
    end

    it "is not reachable by a follower without a membership when the post is supporter-only" do
      band = create(:band, :approved)
      post_record = create(:post, :published, :supporter_only, band: band)
      attachment = attach_pdf(post_record)
      user = create(:user)
      create(:follow, band: band, user: user)
      sign_in user

      get rails_blob_path(attachment, only_path: true)

      expect(response).to have_http_status(:not_found)
    end

    it "is reachable by a user with an active Supporter membership when the post is supporter-only" do
      band = create(:band, :approved)
      post_record = create(:post, :published, :supporter_only, band: band)
      attachment = attach_pdf(post_record)
      user = create(:user)
      create(:membership, band: band, user: user, level: :supporter)
      sign_in user

      get rails_blob_path(attachment, only_path: true)

      expect(response).to have_http_status(:redirect)
    end
  end

  describe "an image embedded in a post's rich text body" do
    def attach_embed(post_record)
      blob = ActiveStorage::Blob.create_and_upload!(
        io: File.open(Rails.root.join("spec/fixtures/files/band_photo.png")),
        filename: "band_photo.png",
        content_type: "image/png"
      )
      post_record.update!(body: ActionText::Content.new.append_attachables([ blob ]))
      post_record.body.embeds.first
    end

    it "is reachable by anyone when the post is published and public" do
      band = create(:band, :approved)
      post_record = create(:post, :published, band: band)
      image = attach_embed(post_record)

      get rails_blob_path(image, only_path: true)

      expect(response).to have_http_status(:redirect)
    end

    it "is not reachable by a visitor when the post is a draft" do
      band = create(:band, :approved)
      post_record = create(:post, band: band)
      image = attach_embed(post_record)

      get rails_blob_path(image, only_path: true)

      expect(response).to have_http_status(:not_found)
    end

    it "is reachable by a band member even when the post is a draft" do
      band = create(:band, :approved)
      post_record = create(:post, band: band)
      user = create(:user)
      create(:band_membership, band: band, user: user)
      image = attach_embed(post_record)
      sign_in user

      get rails_blob_path(image, only_path: true)

      expect(response).to have_http_status(:redirect)
    end
  end
end
