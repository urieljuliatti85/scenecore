class Category < ApplicationRecord
  belongs_to :parent, class_name: "Category", optional: true
  has_many :subcategories, class_name: "Category", foreign_key: :parent_id, dependent: :restrict_with_error, inverse_of: :parent
  has_many :bands, dependent: :nullify

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  validate :parent_must_be_a_root_category

  before_validation :generate_slug, on: :create

  scope :roots, -> { where(parent_id: nil) }

  def root?
    parent_id.nil?
  end

  private

  def parent_must_be_a_root_category
    return if parent.blank?

    errors.add(:parent, "must be a top-level category") unless parent.root?
  end

  def generate_slug
    return if name.blank?

    base = name.to_s.parameterize
    candidate = base
    suffix = 1

    while Category.exists?(slug: candidate)
      suffix += 1
      candidate = "#{base}-#{suffix}"
    end

    self.slug = candidate
  end
end
