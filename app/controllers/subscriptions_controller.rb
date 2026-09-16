class SubscriptionsController < ApplicationController
  before_action :set_band

  def create
    @subscription = @band.subscriptions.find_or_initialize_by(user: current_user)
    authorize @subscription, :join?, policy_class: SubscriptionPolicy

    level = subscription_params[:level]
    price_id = StripePriceResolver.resolve(@band, level)
    customer_id = StripeCustomerResolver.resolve(current_user)

    session = StripeClient.instance.v1.checkout.sessions.create(
      mode: "subscription",
      customer: customer_id,
      line_items: [ { price: price_id, quantity: 1 } ],
      success_url: public_band_url(@band.slug),
      cancel_url: public_band_url(@band.slug),
      metadata: { user_id: current_user.id, band_id: @band.id, level: level }
    )

    @subscription.level = level
    @subscription.status = :pending
    @subscription.stripe_customer_id = customer_id
    @subscription.stripe_checkout_session_id = session.id
    @subscription.save!

    redirect_to session.url, allow_other_host: true
  rescue StripePriceResolver::Error, StripeCustomerResolver::Error => e
    redirect_to public_band_path(@band.slug), alert: e.message
  end

  private

  def set_band
    @band = Band.approved.find(params[:band_id])
  end

  def subscription_params
    params.require(:subscription).permit(:level)
  end
end
