class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :rememberable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :validatable

  has_many :band_memberships, dependent: :destroy
  has_many :bands, through: :band_memberships
  has_many :follows, dependent: :destroy
  has_many :followed_bands, through: :follows, source: :band

  validates :name, presence: true

  # Devise delivers notifications inline, so an unreachable mail provider
  # turns a password reset into a 500. The user can't act on that, and it
  # leaks that something is misconfigured. Report it and let the request
  # finish instead — Devise already renders the same "check your email"
  # response whether or not the address exists.
  def send_devise_notification(notification, *args)
    super
  rescue StandardError => e
    Sentry.capture_exception(e) if defined?(Sentry) && Sentry.initialized?
    Rails.logger.error("Devise #{notification} delivery failed: #{e.class}: #{e.message}")
    nil
  end
end
