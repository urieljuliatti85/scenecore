class Post < ApplicationRecord
  include HasImage

  # Ordered low to high: each level also sees everything below it.
  # "followers" sits below the paid Membership levels since it's the free
  # relationship (Follow) — a Fan/Supporter/Core Member is not assumed to
  # also follow the band, but still outranks a plain follower.
  VISIBILITY_LEVELS = %w[public followers fan supporter core_member].freeze

  belongs_to :band

  has_image :image
  has_rich_text :body

  enum :status, { draft: "draft", published: "published" },
       default: :draft, validate: true
  enum :visibility, VISIBILITY_LEVELS.index_with(&:itself),
       default: :public, validate: true, prefix: true

  validates :title, presence: true

  def visible_to?(user, following: nil)
    return true if visibility_public?
    return false if user.nil?

    membership = band.memberships.find_by(user: user)
    following = band.follows.exists?(user: user) if following.nil?
    return true if visibility_followers? && (following || membership&.grants_access?)

    membership.present? && membership.can_access?(visibility)
  end
end
