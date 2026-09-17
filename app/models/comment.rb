class Comment < ApplicationRecord
  belongs_to :post
  belongs_to :user
  has_many :reports, as: :reportable, dependent: :destroy

  validates :body, presence: true
end
