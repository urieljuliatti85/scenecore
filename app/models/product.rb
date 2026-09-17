class Product < ApplicationRecord
  belongs_to :band
  has_many :variants, class_name: "ProductVariant", dependent: :destroy

  accepts_nested_attributes_for :variants

  enum :status, { draft: "draft", published: "published" }, default: :draft, validate: true
  enum :source, { manual: "manual", discogs: "discogs" }, default: :manual, validate: true

  validates :name, presence: true
  validates :discogs_release_id, uniqueness: { scope: :band_id }, allow_nil: true
  validates :discogs_release_id, presence: true, if: :discogs?

  scope :published, -> { where(status: :published) }

  def discogs_url
    return if discogs_release_id.blank?

    "https://www.discogs.com/release/#{discogs_release_id}"
  end
end
