class Track < ApplicationRecord
  SPOTIFY_TRACK_URL_FORMAT = %r{\Ahttps://open\.spotify\.com/track/([a-zA-Z0-9]{22})(\?.*)?\z}

  belongs_to :album
  has_one :band, through: :album

  enum :status, { draft: "draft", published: "published" },
       default: :draft, validate: true

  validates :title, presence: true
  validates :track_number, presence: true
  validates :spotify_url, format: { with: SPOTIFY_TRACK_URL_FORMAT, message: "must be a Spotify track link" }, allow_blank: true

  def spotify_embed_url
    return if spotify_url.blank?

    match = spotify_url.match(SPOTIFY_TRACK_URL_FORMAT)
    return unless match

    "https://open.spotify.com/embed/track/#{match[1]}"
  end
end
