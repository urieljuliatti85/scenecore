class Band < ApplicationRecord
  has_many :band_memberships, dependent: :destroy
  has_many :members, through: :band_memberships, source: :user
  has_many :tracks, dependent: :destroy

  enum :status, { pending: "pending", approved: "approved", rejected: "rejected" },
       default: :pending, validate: true

  scope :approved, -> { where(status: :approved) }

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true

  before_validation :generate_slug, on: :create

  private

  def generate_slug
    return if name.blank?

    base = name.to_s.parameterize
    candidate = base
    suffix = 1

    while Band.exists?(slug: candidate)
      suffix += 1
      candidate = "#{base}-#{suffix}"
    end

    self.slug = candidate
  end
end
