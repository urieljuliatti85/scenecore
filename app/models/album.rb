class Album < ApplicationRecord
  belongs_to :band
  has_many :tracks, dependent: :destroy
  has_many :admin_action_logs, as: :subject, dependent: :destroy

  enum :status, { draft: "draft", published: "published" },
       default: :draft, validate: true

  validates :title, presence: true
end
