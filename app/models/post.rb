class Post < ApplicationRecord
  include HasImage

  belongs_to :band

  has_image :image
  has_rich_text :body

  enum :status, { draft: "draft", published: "published" },
       default: :draft, validate: true
  enum :visibility, { public: "public", followers: "followers", subscribers: "subscribers" },
       default: :public, validate: true, prefix: true

  validates :title, presence: true
end
