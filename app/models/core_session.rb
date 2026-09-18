# A membership-only gathering (docs/band-admin.md §§14–15). Its audience
# can start at Supporter for an exclusive stream or at Core Member for a
# private Q&A/meetup. Attendance is tracked in-app via RSVP, capped by an
# optional capacity, rather than building a ticketing system here.
class CoreSession < ApplicationRecord
  SESSION_TYPES = %w[video audio qa listening_party meet_greet].freeze
  AUDIENCE_LEVELS = %w[supporter core_member].freeze

  belongs_to :band
  has_many :rsvps, class_name: "CoreSessionRsvp", dependent: :destroy
  has_many :attendees, through: :rsvps, source: :user

  enum :session_type, SESSION_TYPES.index_with(&:itself), validate: true
  enum :status, { draft: "draft", published: "published" },
       default: :draft, validate: true
  enum :audience_level, AUDIENCE_LEVELS.index_with(&:itself),
       default: :core_member, validate: true, prefix: :audience

  validates :title, presence: true
  validates :starts_at, presence: true
  validates :capacity, numericality: { greater_than: 0, allow_nil: true }
  validates :access_url, format: { with: Band::URL_FORMAT, message: "must be a valid URL" }, allow_blank: true

  def seats_available?
    capacity.nil? || rsvps.count < capacity
  end

  def spots_remaining
    return nil if capacity.nil?

    [ capacity - rsvps.count, 0 ].max
  end

  # Access to session details is independent of whether seats remain — a
  # full session is still visible to members it is for, just not joinable.
  # The Membership model owns hierarchy inheritance here.
  def visible_to?(user)
    return false if user.nil?

    band.memberships.find_by(user: user)&.can_access?(audience_level) || false
  end

  def rsvpable_by?(user)
    published? && seats_available? && visible_to?(user)
  end

  def rsvped_by?(user)
    return false if user.nil?

    rsvps.exists?(user: user)
  end

  def access_link
    url = access_url.to_s
    url if url.match?(Band::URL_FORMAT)
  end
end
