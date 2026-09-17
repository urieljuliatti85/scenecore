class Post < ApplicationRecord
  include HasImage
  include HasAttachments
  include MembershipGatedVisibility

  belongs_to :band
  has_many :comments, dependent: :destroy
  has_many :reports, as: :reportable, dependent: :destroy

  has_image :image
  has_attachments :attachments
  has_rich_text :body

  enum :status, { draft: "draft", published: "published" },
       default: :draft, validate: true
  enum :post_type, { announcement: "announcement", composition_journal: "composition_journal" },
       default: :announcement, validate: true

  validates :title, presence: true
end
