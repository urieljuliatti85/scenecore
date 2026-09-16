class Band < ApplicationRecord
  include HasImage

  SOCIAL_LINK_ATTRIBUTES = %i[spotify_url youtube_url instagram_url bandcamp_url website_url].freeze
  URL_FORMAT = %r{\Ahttps?://[^\s/$.?#].[^\s]*\z}i

  has_many :band_memberships, dependent: :destroy
  has_many :members, through: :band_memberships, source: :user
  has_many :memberships, dependent: :destroy
  has_many :subscriptions, dependent: :destroy
  has_many :band_membership_prices, dependent: :destroy
  has_many :albums, dependent: :destroy
  has_many :follows, dependent: :destroy
  has_many :followers, through: :follows, source: :user
  has_many :posts, dependent: :destroy
  has_many :events, dependent: :destroy
  has_many :polls, dependent: :destroy
  has_many :admin_action_logs, as: :subject, dependent: :destroy
  belongs_to :category, optional: true
  has_image :photo

  enum :status, { pending: "pending", approved: "approved", rejected: "rejected", suspended: "suspended" },
       default: :pending, validate: true

  scope :approved, -> { where(status: :approved) }
  scope :featured, -> { approved.order(created_at: :desc).limit(1) }

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :spotify_url, :youtube_url, :instagram_url, :bandcamp_url, :website_url,
            format: { with: URL_FORMAT, message: "must be a valid URL" }, allow_blank: true

  before_validation :generate_slug, on: :create

  def followers_count
    followers.size
  end

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
end
