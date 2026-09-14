class Track < ApplicationRecord
  belongs_to :band

  enum :status, { draft: "draft", published: "published" },
       default: :draft, validate: true

  validates :title, presence: true
end
