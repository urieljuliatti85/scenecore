class Album < ApplicationRecord
  include HasImage

  SPOTIFY_ALBUM_URL = "https://open.spotify.com/album/%s".freeze
  SPOTIFY_ID_FORMAT = /\A[a-zA-Z0-9]{22}\z/
  BANDCAMP_EMBED_URL_FORMAT = %r{\Ahttps://bandcamp\.com/EmbeddedPlayer/[a-zA-Z0-9=/_-]+\z}

  belongs_to :band
  has_many :admin_action_logs, as: :subject, dependent: :destroy
  has_many :ratings, dependent: :destroy
  has_many :album_credits, dependent: :destroy
  has_many :credited_users, through: :album_credits, source: :user
  has_image :cover

  enum :status, { draft: "draft", published: "published" },
       default: :draft, validate: true
  enum :early_access_level, Membership::LEVELS.index_with(&:itself), prefix: :early_access, validate: { allow_nil: true }

  validates :title, presence: true
  validates :spotify_id, format: { with: SPOTIFY_ID_FORMAT }, allow_nil: true
  validates :bandcamp_embed_url, format: { with: BANDCAMP_EMBED_URL_FORMAT }, allow_blank: true
  validates :early_access_until, presence: true, if: :early_access_level?
  validates :early_access_level, presence: true, if: :early_access_until?

  # An album is a pointer to Spotify rather than a track listing of its
  # own, so the link is derived from the id captured at import instead of
  # being stored a second time.
  #
  # The id is re-checked here rather than trusted: this value ends up in an
  # href, and the validation above only guards records saved through the
  # model. A row written another way (a fixture, a console, a future import
  # path) must not be able to put `javascript:` or an attacker's domain in
  # front of a visitor.
  def spotify_url
    id = spotify_link_id
    return if id.nil?

    format(SPOTIFY_ALBUM_URL, id)
  end

  # The id only if it really is one, for views that build the href from a
  # literal so the scheme and host are visibly fixed at the call site.
  def spotify_link_id
    spotify_id if spotify_id.to_s.match?(SPOTIFY_ID_FORMAT)
  end

  # The embed URL only if it really is a bandcamp.com/EmbeddedPlayer/...
  # URL — re-checked the same way as spotify_link_id above, since this
  # value ends up as an iframe src and validation only guards records
  # saved through the model.
  def bandcamp_embed_link
    bandcamp_embed_url if bandcamp_embed_url.to_s.match?(BANDCAMP_EMBED_URL_FORMAT)
  end

  def cover_url
    return url_for(cover) if cover.attached?

    spotify_cover_url
  end

  def average_rating
    ratings.average(:score)&.round(1)
  end

  def ratings_count
    ratings.count
  end

  def in_early_access?
    early_access_level.present? && early_access_until.present? && early_access_until > Time.current
  end

  def visible_to?(user)
    return true unless in_early_access?

    return false if user.nil?

    membership = band.memberships.find_by(user: user)
    membership.present? && membership.can_access?(early_access_level)
  end

  # The minimum Membership level a viewer needs to see this right now, or
  # nil when it's already public — used by the public band page to explain
  # a locked album instead of just omitting it (docs/band-admin.md §37).
  def required_level
    early_access_level if in_early_access?
  end

  private

  def url_for(attachment)
    Rails.application.routes.url_helpers.rails_blob_path(attachment, only_path: true)
  end
end
