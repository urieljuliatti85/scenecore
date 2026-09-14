module HasImage
  extend ActiveSupport::Concern

  IMAGE_CONTENT_TYPES = %w[image/png image/jpeg image/webp].freeze
  IMAGE_MAX_SIZE = 5.megabytes

  class_methods do
    def has_image(name)
      has_one_attached name

      validate -> { validate_image_attachment(name) }
    end
  end

  private

  def validate_image_attachment(name)
    image = public_send(name)
    return unless image.attached?

    unless image.content_type.in?(IMAGE_CONTENT_TYPES)
      errors.add(name, "must be a PNG, JPEG, or WebP image")
    end

    if image.byte_size > IMAGE_MAX_SIZE
      errors.add(name, "must be smaller than #{IMAGE_MAX_SIZE / 1.megabyte}MB")
    end
  end
end
