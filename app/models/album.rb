class Album < ApplicationRecord
  include HasImage

  SPOTIFY_ALBUM_URL = "https://open.spotify.com/album/%s".freeze

  belongs_to :band
  has_many :admin_action_logs, as: :subject, dependent: :destroy
  has_image :cover

  enum :status, { draft: "draft", published: "published" },
       default: :draft, validate: true

  validates :title, presence: true

  # An album is a pointer to Spotify rather than a track listing of its
  # own, so the link is derived from the id captured at import instead of
  # being stored a second time.
  def spotify_url
    return if spotify_id.blank?

    format(SPOTIFY_ALBUM_URL, spotify_id)
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
