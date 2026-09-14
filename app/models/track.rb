class Track < ApplicationRecord
  SPOTIFY_TRACK_URL_FORMAT = %r{\Ahttps://open\.spotify\.com/track/[a-zA-Z0-9]{22}(\?.*)?\z}

  belongs_to :band

  enum :status, { draft: "draft", published: "published" },
       default: :draft, validate: true

  validates :title, presence: true
  validates :spotify_url, format: { with: SPOTIFY_TRACK_URL_FORMAT, message: "must be a Spotify track link" }, allow_blank: true
end
