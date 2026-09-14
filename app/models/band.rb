class Band < ApplicationRecord
  PHOTO_CONTENT_TYPES = %w[image/png image/jpeg image/webp].freeze
  PHOTO_MAX_SIZE = 5.megabytes
  SOCIAL_LINK_ATTRIBUTES = %i[spotify_url youtube_url instagram_url website_url].freeze
  URL_FORMAT = %r{\Ahttps?://[^\s/$.?#].[^\s]*\z}i

  has_many :band_memberships, dependent: :destroy
  has_many :members, through: :band_memberships, source: :user
  has_many :tracks, dependent: :destroy
  has_one_attached :photo

  enum :status, { pending: "pending", approved: "approved", rejected: "rejected" },
       default: :pending, validate: true

  scope :approved, -> { where(status: :approved) }
  scope :featured, -> { approved.order(created_at: :desc).limit(1) }

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  validate :photo_is_valid
  validates :spotify_url, :youtube_url, :instagram_url, :website_url,
            format: { with: URL_FORMAT, message: "must be a valid URL" }, allow_blank: true

  before_validation :generate_slug, on: :create

  def social_links
    SOCIAL_LINK_ATTRIBUTES.filter_map do |attribute|
      url = public_send(attribute)
      [ attribute, url ] if url.present?
    end.to_h
  end

  private

  def generate_slug
    return if name.blank?

    base = name.to_s.parameterize
    candidate = base
    suffix = 1

    while Band.exists?(slug: candidate)
      suffix += 1
      candidate = "#{base}-#{suffix}"
    end

    self.slug = candidate
  end

  def photo_is_valid
    return unless photo.attached?

    unless photo.content_type.in?(PHOTO_CONTENT_TYPES)
      errors.add(:photo, "must be a PNG, JPEG, or WebP image")
    end

    if photo.byte_size > PHOTO_MAX_SIZE
      errors.add(:photo, "must be smaller than #{PHOTO_MAX_SIZE / 1.megabyte}MB")
    end
  end
end
