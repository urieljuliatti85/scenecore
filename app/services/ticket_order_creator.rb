class TicketOrderCreator
  Error = Class.new(StandardError)
  # Stripe requires expires_at to be at least 30 minutes in the future.
  # One extra minute keeps the value valid while the request and DB work run.
  CHECKOUT_WINDOW = 31.minutes

  def self.call(user:, ticket_batch:, quantity:)
    new(user: user, ticket_batch: ticket_batch, quantity: quantity).call
  end

  def initialize(user:, ticket_batch:, quantity:)
    @user = user
    @ticket_batch = ticket_batch
    @quantity = Integer(quantity)
  rescue ArgumentError, TypeError
    @quantity = 0
  end

  def call
    @ticket_batch.with_lock do
      raise Error, "This ticket batch is not on sale." unless @ticket_batch.on_sale?
      raise Error, "Choose between 1 and #{TicketBatch::MAXIMUM_PER_ORDER} tickets." unless @quantity.between?(1, TicketBatch::MAXIMUM_PER_ORDER)
      raise Error, "Only #{@ticket_batch.remaining_quantity} tickets remain." if @quantity > @ticket_batch.remaining_quantity

      total = @ticket_batch.price_cents * @quantity
      @user.ticket_orders.create!(
        ticket_batch: @ticket_batch,
        quantity: @quantity,
        unit_price_cents: @ticket_batch.price_cents,
        total_cents: total,
        platform_fee_cents: (total * PlatformSetting.current.store_fee_percentage / 100.0).round,
        expires_at: CHECKOUT_WINDOW.from_now
      )
    end
  end
end
