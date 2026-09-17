# A fan's in-progress selection of one band's product variants prior to
# checkout (docs/database.md Carts). At most one active cart exists per
# user platform-wide, enforced by a partial unique index on
# carts.user_id — see the create_carts migration, not just this model.
class Cart < ApplicationRecord
  belongs_to :user
  belongs_to :band
  has_many :cart_items, dependent: :destroy

  enum :status, { active: "active", converted: "converted", abandoned: "abandoned" },
       default: :active, validate: true

  def subtotal_cents
    cart_items.sum { |item| item.quantity * item.product_variant.price_cents }
  end
end
