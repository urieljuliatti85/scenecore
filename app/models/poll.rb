class Poll < ApplicationRecord
  include MembershipGatedVisibility

  belongs_to :band
  has_many :poll_options, -> { order(:position, :id) }, dependent: :destroy, inverse_of: :poll
  accepts_nested_attributes_for :poll_options, reject_if: ->(attrs) { attrs["label"].blank? }

  enum :status, { draft: "draft", published: "published" },
       default: :draft, validate: true

  validates :question, presence: true
  validate :at_least_two_options

  def open?
    return false unless published?
    return false if opens_at.present? && opens_at > Time.current
    return false if closes_at.present? && closes_at < Time.current

    true
  end

  def voteable_by?(user)
    user.present? && open? && visible_to?(user)
  end

  def voted_by?(user)
    return false if user.nil?

    PollVote.where(poll_option: poll_options).exists?(user: user)
  end

  private

  def at_least_two_options
    real_options = poll_options.reject(&:marked_for_destruction?)
    errors.add(:base, "must have at least two options") if real_options.size < 2
  end
end
