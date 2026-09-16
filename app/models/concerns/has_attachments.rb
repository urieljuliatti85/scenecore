module HasAttachments
  extend ActiveSupport::Concern

  ATTACHMENT_CONTENT_TYPES = %w[audio/wav audio/mpeg audio/mp3 application/pdf].freeze
  ATTACHMENT_MAX_SIZE = 25.megabytes

  class_methods do
    def has_attachments(name)
      has_many_attached name

      validate -> { validate_attachments(name) }
    end
  end

  private

  def validate_attachments(name)
    public_send(name).each do |attachment|
      unless attachment.content_type.in?(HasAttachments::ATTACHMENT_CONTENT_TYPES)
        errors.add(name, "must be a WAV, MP3, or PDF file")
      end

      if attachment.byte_size > HasAttachments::ATTACHMENT_MAX_SIZE
        errors.add(name, "must be smaller than #{HasAttachments::ATTACHMENT_MAX_SIZE / 1.megabyte}MB")
      end
    end
  end
end
