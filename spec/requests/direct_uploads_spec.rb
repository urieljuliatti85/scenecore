require "rails_helper"

RSpec.describe "Direct uploads", type: :request do
  def blob_params(overrides = {})
    {
      blob: {
        filename: "photo.png",
        byte_size: 1024,
        checksum: Digest::MD5.base64digest("x"),
        content_type: "image/png"
      }.merge(overrides)
    }
  end

  it "requires authentication" do
    post post_direct_uploads_path, params: blob_params

    expect(response).to redirect_to(new_user_session_path)
  end

  it "creates a blob for a signed-in user" do
    sign_in create(:user)

    expect {
      post post_direct_uploads_path, params: blob_params
    }.to change(ActiveStorage::Blob, :count).by(1)

    expect(response).to have_http_status(:ok)
  end

  it "rejects a non-image content type" do
    sign_in create(:user)

    expect {
      post post_direct_uploads_path, params: blob_params(content_type: "text/plain")
    }.not_to change(ActiveStorage::Blob, :count)

    expect(response).to have_http_status(:unprocessable_entity)
  end

  it "rejects a file larger than the maximum size" do
    sign_in create(:user)

    expect {
      post post_direct_uploads_path, params: blob_params(byte_size: HasImage::IMAGE_MAX_SIZE + 1)
    }.not_to change(ActiveStorage::Blob, :count)

    expect(response).to have_http_status(:unprocessable_entity)
  end

  it "neutralizes Active Storage's own unauthenticated direct_uploads route" do
    post "/rails/active_storage/direct_uploads", params: blob_params

    expect(response).to have_http_status(:not_found)
  end
end
