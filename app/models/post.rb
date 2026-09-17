class Post < ApplicationRecord
  include HasImage
  include HasAttachments
  include MembershipGatedVisibility

  belongs_to :band
  has_many :comments, -> { order(created_at: :asc) }, dependent: :destroy
  has_many :reports, as: :reportable, dependent: :destroy

  has_image :image
  has_attachments :attachments
  has_rich_text :body

  enum :status, { draft: "draft", published: "published" },
       default: :draft, validate: true
  enum :post_type, {
    announcement: "announcement",
    composition_journal: "composition_journal",
    rehearsal_recording: "rehearsal_recording"
  }, default: :announcement, validate: true
  enum :early_access_level, Membership::LEVELS.index_with(&:itself), prefix: :early_access, validate: { allow_nil: true }

  validates :title, presence: true
  validates :early_access_until, presence: true, if: :early_access_level?
  validates :early_access_level, presence: true, if: :early_access_until?

  # docs/band-admin.md §19 — early access is a membership rule layered on
  # top of the post's own visibility, not a separate copy of the content.
  # A post that's already gated to a paid level (visibility: :supporter)
  # can still have an earlier release window for :core_member; a
  # public/followers post can have a window restricted to a paid level
  # before it opens up to everyone.
  def in_early_access?
    early_access_level.present? && early_access_until.present? && early_access_until > Time.current
  end

  def visible_to?(user, following: nil)
    return super unless in_early_access?
    return false if user.nil?

    membership = band.memberships.find_by(user: user)
    membership.present? && membership.can_access?(early_access_level)
  end

  # The minimum Membership level a viewer needs to see this right now.
  # Early access takes priority over the post's own visibility while the
  # window is open, since it's the stricter of the two at that moment.
  def required_level
    return early_access_level if in_early_access?

    super
  end
end
