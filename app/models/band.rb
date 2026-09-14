class Band < ApplicationRecord
  PHOTO_CONTENT_TYPES = %w[image/png image/jpeg image/webp].freeze
  PHOTO_MAX_SIZE = 5.megabytes

  has_many :band_memberships, dependent: :destroy
  has_many :members, through: :band_memberships, source: :user
  has_one_attached :photo

  enum :status, { pending: "pending", approved: "approved", rejected: "rejected" },
       default: :pending, validate: true

  scope :approved, -> { where(status: :approved) }
  scope :featured, -> { approved.order(created_at: :desc).limit(1) }

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  validate :photo_is_valid

  before_validation :generate_slug, on: :create

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
