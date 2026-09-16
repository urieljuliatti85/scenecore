class Event < ApplicationRecord
  URL_FORMAT = Band::URL_FORMAT

  belongs_to :band

  enum :status, { draft: "draft", published: "published" },
       default: :draft, validate: true

  scope :upcoming, -> { where("starts_at >= ?", Time.current).order(:starts_at) }
  scope :chronological, -> { order(:starts_at) }

  validates :title, presence: true
  validates :location, presence: true
  validates :starts_at, presence: true
  validates :ticket_url, format: { with: URL_FORMAT, message: "must be a valid URL" },
            allow_blank: true

  # The URL ends up in an href. Validation only guards records saved
  # through the model, so a row written another way must not be able to
  # put `javascript:` in front of a visitor.
  def ticket_link
    url = ticket_url.to_s
    url if url.match?(URL_FORMAT)
  end
end
