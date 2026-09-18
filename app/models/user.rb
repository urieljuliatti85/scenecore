class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :rememberable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :validatable

  has_many :band_memberships, dependent: :destroy
  has_many :bands, through: :band_memberships
  has_many :follows, dependent: :destroy
  has_many :followed_bands, through: :follows, source: :band
  has_many :memberships, dependent: :destroy
  has_many :subscriptions, dependent: :destroy
  has_many :carts, dependent: :destroy
  has_many :orders, dependent: :destroy
  has_many :ticket_orders, dependent: :restrict_with_error
  has_many :tickets, dependent: :restrict_with_error
  has_many :checked_in_tickets, class_name: "Ticket", foreign_key: :checked_in_by_id,
           inverse_of: :checked_in_by, dependent: :restrict_with_error
  has_many :ratings, dependent: :destroy
  has_many :poll_votes, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :album_credits, dependent: :destroy
  has_many :core_session_rsvps, dependent: :destroy
  has_many :direct_message_threads, dependent: :destroy
  has_many :direct_messages, dependent: :destroy
  has_many :reports, foreign_key: :reporter_id, inverse_of: :reporter, dependent: :destroy
  has_many :band_admin_requests, dependent: :destroy

  validates :name, presence: true

  before_destroy :ensure_not_last_platform_admin
  before_update :ensure_not_demoting_last_platform_admin, if: :platform_admin_changed?

  private

  def ensure_not_last_platform_admin
    return unless platform_admin?
    return unless User.where(platform_admin: true).where.not(id: id).none?

    errors.add(:base, "cannot remove the last platform administrator")
    throw :abort
  end

  def ensure_not_demoting_last_platform_admin
    return unless platform_admin_was && !platform_admin?
    return unless User.where(platform_admin: true).where.not(id: id).none?

    errors.add(:base, "cannot demote the last platform administrator")
    throw :abort
  end
end
