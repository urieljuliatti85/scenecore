class ContactMessage < ApplicationRecord
  EMAIL_FORMAT = URI::MailTo::EMAIL_REGEXP
  MESSAGE_MAX_LENGTH = 5_000

  validates :name, presence: true, length: { maximum: 255 }
  validates :email, presence: true, format: { with: EMAIL_FORMAT, message: "must be a valid email address" }
  validates :band, length: { maximum: 255 }
  validates :message, presence: true, length: { maximum: MESSAGE_MAX_LENGTH }
end
