# A Core Member-only gathering (docs/band-admin.md §15) — always
# restricted to Core Member, unlike Event which is public with an
# external ticket link. Attendance is tracked in-app via RSVP, capped
# by an optional capacity, rather than pointed at an external ticketing
# system.
class CoreSession < ApplicationRecord
  SESSION_TYPES = %w[video audio qa listening_party meet_greet].freeze

  belongs_to :band
  has_many :rsvps, class_name: "CoreSessionRsvp", dependent: :destroy
  has_many :attendees, through: :rsvps, source: :user

  enum :session_type, SESSION_TYPES.index_with(&:itself), validate: true
  enum :status, { draft: "draft", published: "published" },
       default: :draft, validate: true

  validates :title, presence: true
  validates :starts_at, presence: true
  validates :capacity, numericality: { greater_than: 0, allow_nil: true }

  def seats_available?
    capacity.nil? || rsvps.count < capacity
  end

  def spots_remaining
    return nil if capacity.nil?

    [ capacity - rsvps.count, 0 ].max
  end

  # Core Member access to the session's details, independent of whether
  # seats remain right now — a full session is still visible to the
  # members it's for, just not joinable. See #rsvpable_by? for that.
  def visible_to?(user)
    return false if user.nil?

    band.memberships.find_by(user: user)&.can_access?(:core_member) || false
  end

  def rsvpable_by?(user)
    published? && seats_available? && visible_to?(user)
  end

  def rsvped_by?(user)
    return false if user.nil?

    rsvps.exists?(user: user)
  end
end
