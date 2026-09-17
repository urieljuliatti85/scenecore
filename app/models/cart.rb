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

  # Charged once per distinct product, not per unit — two copies of the same
  # record ship together. The platform-wide calculation method is still an
  # open product question (docs/product.md §7); until one is chosen this
  # sums the per-product figures bands enter by hand.
  def shipping_cents
    cart_items.map { |item| item.product_variant.product }.uniq.sum(&:shipping_cents)
  end

  def total_cents
    subtotal_cents + shipping_cents
  end
end
