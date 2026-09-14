class Album < ApplicationRecord
  include HasImage

  belongs_to :band
  has_many :tracks, dependent: :destroy
  has_many :admin_action_logs, as: :subject, dependent: :destroy
  has_image :cover

  enum :status, { draft: "draft", published: "published" },
       default: :draft, validate: true

  validates :title, presence: true

  def cover_url
    return url_for(cover) if cover.attached?

    spotify_cover_url
  end

  private

  def url_for(attachment)
    Rails.application.routes.url_helpers.rails_blob_path(attachment, only_path: true)
  end
end
