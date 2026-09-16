class Album < ApplicationRecord
  include HasImage

  SPOTIFY_ALBUM_URL = "https://open.spotify.com/album/%s".freeze
  SPOTIFY_ID_FORMAT = /\A[a-zA-Z0-9]{22}\z/

  belongs_to :band
  has_many :admin_action_logs, as: :subject, dependent: :destroy
  has_image :cover

  enum :status, { draft: "draft", published: "published" },
       default: :draft, validate: true

  validates :title, presence: true
  validates :spotify_id, format: { with: SPOTIFY_ID_FORMAT }, allow_nil: true

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

  def cover_url
    return url_for(cover) if cover.attached?

    spotify_cover_url
  end

  private

  def url_for(attachment)
    Rails.application.routes.url_helpers.rails_blob_path(attachment, only_path: true)
  end
end
