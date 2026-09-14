class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :rememberable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :validatable

  has_many :band_memberships, dependent: :destroy
  has_many :bands, through: :band_memberships

  validates :name, presence: true
end
