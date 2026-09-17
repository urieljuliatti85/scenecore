class Product < ApplicationRecord
  belongs_to :band
  has_many :variants, class_name: "ProductVariant", dependent: :destroy

  accepts_nested_attributes_for :variants

  enum :status, { draft: "draft", published: "published" }, default: :draft, validate: true

  validates :name, presence: true

  scope :published, -> { where(status: :published) }
end
