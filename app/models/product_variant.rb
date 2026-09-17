class ProductVariant < ApplicationRecord
  InsufficientStock = Class.new(StandardError)

  belongs_to :product
  has_many :cart_items, dependent: :destroy

  validates :sku, presence: true, uniqueness: true
  validates :name, presence: true
  validates :price_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :stock_quantity, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  def sold_out?
    stock_quantity.zero?
  end

  # Guards against two concurrent purchases both consuming stock from the
  # same pre-decrement count (docs/database.md ProductVariants) — the
  # WHERE clause makes the decrement atomic at the database level rather
  # than trusting a Ruby-level read-then-write.
  def decrement_stock!(amount)
    updated = self.class.where(id: id).where("stock_quantity >= ?", amount)
                  .update_all([ "stock_quantity = stock_quantity - ?", amount ])
    raise InsufficientStock, "Not enough stock for #{sku}" if updated.zero?

    reload
  end
end
