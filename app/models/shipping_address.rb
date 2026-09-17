class ShippingAddress < ApplicationRecord
  belongs_to :order

  validates :recipient_name, :line1, :city, :state, :postal_code, :country, presence: true
end
