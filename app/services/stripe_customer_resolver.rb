# Finds or creates the Stripe Customer for a user, reused across every
# band they subscribe to rather than creating one Customer per
# subscription.
class StripeCustomerResolver
  Error = Class.new(StandardError)

  def self.resolve(user)
    new(user).resolve
  end

  def initialize(user)
    @user = user
  end

  def resolve
    return @user.stripe_customer_id if @user.stripe_customer_id.present?

    customer = StripeClient.instance.v1.customers.create(
      email: @user.email,
      name: @user.name,
      metadata: { user_id: @user.id }
    )

    @user.update!(stripe_customer_id: customer.id)
    customer.id
  rescue ActiveRecord::RecordNotUnique
    @user.reload.stripe_customer_id
  rescue Stripe::StripeError => e
    raise Error, "Could not create a Stripe customer for this user: #{e.message}"
  end
end
