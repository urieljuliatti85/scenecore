class Band < ApplicationRecord
  include HasImage

  SOCIAL_LINK_ATTRIBUTES = %i[spotify_url youtube_url instagram_url bandcamp_url website_url].freeze
  URL_FORMAT = %r{\Ahttps?://[^\s/$.?#].[^\s]*\z}i
  COUNTRY_CODE_FORMAT = /\A[A-Z]{2}\z/

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
  has_many :core_sessions, dependent: :destroy
  has_many :direct_message_threads, dependent: :destroy
  has_many :merch_discounts, dependent: :destroy
  has_many :polls, dependent: :destroy
  has_many :admin_action_logs, as: :subject, dependent: :destroy
  has_many :products, dependent: :destroy
  has_many :carts, dependent: :destroy
  has_many :orders, dependent: :destroy
  belongs_to :category, optional: true
  has_image :photo

  enum :status, { pending: "pending", approved: "approved", rejected: "rejected", suspended: "suspended" },
       default: :pending, validate: true
  enum :stripe_connect_status, { not_started: "not_started", onboarding: "onboarding", active: "active", restricted: "restricted" },
       default: :not_started, validate: true, prefix: :stripe_connect

  scope :approved, -> { where(status: :approved) }

  scope :explicitly_featured, -> { approved.where(featured: true) }

  # A band can only take money once Stripe has cleared its connected
  # account (ADR-007/ADR-008). An onboarding or restricted account can
  # still hold a Connect id, so the id alone is not enough to charge
  # against — both the Store and memberships route payment to it.
  def payouts_ready?
    stripe_connect_active? && stripe_connect_account_id.present?
  end

  # The home page hero. A platform administrator may pin one band via
  # Band#feature!; with nothing pinned this falls back to the most
  # recently approved band, which is what the home page showed before
  # featuring became explicit.
  scope :featured, lambda {
    pinned = explicitly_featured.limit(1)
    pinned.exists? ? pinned : approved.order(created_at: :desc).limit(1)
  }

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :country_code, presence: true, format: { with: COUNTRY_CODE_FORMAT, message: "must be a two-letter ISO country code" }
  validates :spotify_url, :youtube_url, :instagram_url, :bandcamp_url, :website_url,
            format: { with: URL_FORMAT, message: "must be a valid URL" }, allow_blank: true
  validate :country_code_unchanged_after_connect, on: :update

  before_validation :normalize_country_code
  before_validation :generate_slug, on: :create

  def followers_count
    followers.size
  end

  # ADR-007: Store checkout requires an active Stripe Connect account —
  # a band mid-onboarding or restricted by Stripe cannot accept payment.
  def store_open?
    stripe_connect_active? && stripe_connect_account_id.present?
  end

  # Unpinning the previous band and pinning this one must happen together:
  # the partial unique index on featured rejects a second featured row, so
  # doing it in two separate statements would fail half the time.
  def feature!
    self.class.transaction do
      self.class.where(featured: true).where.not(id: id).update_all(featured: false)
      update!(featured: true)
    end
  end

  def unfeature!
    update!(featured: false)
  end

  def social_links
    SOCIAL_LINK_ATTRIBUTES.filter_map do |attribute|
      url = public_send(attribute)
      [ attribute, url ] if url.present?
    end.to_h
  end

  private

  def normalize_country_code
    self.country_code = country_code.to_s.strip.upcase if country_code.present?
  end

  def country_code_unchanged_after_connect
    return unless stripe_connect_account_id.present? && will_save_change_to_country_code?

    errors.add(:country_code, "cannot be changed after Stripe Connect setup has started")
  end

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
