class DirectUploadsController < ApplicationController
  include ActiveStorage::SetCurrent

  def create
    unless blob_args[:content_type].in?(HasImage::IMAGE_CONTENT_TYPES)
      return render json: { error: "must be a PNG, JPEG, or WebP image" }, status: :unprocessable_entity
    end

    if blob_args[:byte_size].to_i > HasImage::IMAGE_MAX_SIZE
      return render json: { error: "must be smaller than #{HasImage::IMAGE_MAX_SIZE / 1.megabyte}MB" }, status: :unprocessable_entity
    end

    blob = ActiveStorage::Blob.create_before_direct_upload!(**blob_args)
    render json: direct_upload_json(blob)
  end

  private

  def blob_args
    params.expect(blob: [ :filename, :byte_size, :checksum, :content_type, metadata: {} ]).to_h.symbolize_keys
  end

  def direct_upload_json(blob)
    blob.as_json(root: false, methods: :signed_id).merge(direct_upload: {
      url: blob.service_url_for_direct_upload,
      headers: blob.service_headers_for_direct_upload
    })
  end
end
