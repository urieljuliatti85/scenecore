class DirectMessage < ApplicationRecord
  belongs_to :direct_message_thread
  belongs_to :user

  validates :body, presence: true, length: { maximum: 2000 }
end
