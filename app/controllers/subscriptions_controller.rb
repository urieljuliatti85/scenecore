class SubscriptionsController < ApplicationController
  before_action :set_band, except: [ :index ]

  def index
    @subscriptions = current_user.subscriptions.includes(:band).order(created_at: :desc)
  end

  def create
    @subscription = @band.subscriptions.find_or_initialize_by(user: current_user)
    authorize @subscription, :join?, policy_class: SubscriptionPolicy

    # Without a cleared connected account there is nowhere to send the
    # band's 85%, so the fan is stopped before a subscription exists
    # rather than being charged into an arrangement that cannot pay out.
    unless @band.payouts_ready?
      return redirect_to public_band_path(@band.slug), alert: "#{@band.name} can't take payments yet."
    end

    level = subscription_params[:level]
    price_id = StripePriceResolver.resolve(@band, level)

    # Already paying for this band: switch the existing subscription's
    # price rather than starting a second one, which would bill the fan
    # twice for the same band.
    return switch_level(level, price_id) if @subscription.active? && @subscription.stripe_subscription_id.present?

    customer_id = StripeCustomerResolver.resolve(current_user)

    session = StripeClient.instance.v1.checkout.sessions.create(
      mode: "subscription",
      customer: customer_id,
      line_items: [ { price: price_id, quantity: 1 } ],
      subscription_data: {
        application_fee_percent: PlatformSetting.current.membership_fee_percentage,
        transfer_data: { destination: @band.stripe_connect_account_id }
      },
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

  def destroy
    @subscription = @band.subscriptions.find_by!(user: current_user)
    authorize @subscription, :cancel?, policy_class: SubscriptionPolicy

    # The customer.subscription.deleted webhook is the source of truth for
    # local status (see StripeSubscriptionDeletedHandler) — the local
    # updates inside the canceller just give the user immediate feedback
    # instead of waiting on webhook delivery.
    SubscriptionCanceller.call(band: @band, user: current_user)

    redirect_to public_band_path(@band.slug), notice: "Your subscription to #{@band.name} has been cancelled."
  rescue SubscriptionCanceller::Error => e
    redirect_to public_band_path(@band.slug), alert: "Could not cancel your subscription: #{e.message}"
  end

  private

  def switch_level(level, price_id)
    StripeSubscriptionSwitcher.call(@subscription.stripe_subscription_id, price_id)
    @subscription.update!(level: level)

    membership = @band.memberships.find_by(user: current_user)
    membership&.update!(level: level)

    redirect_to public_band_path(@band.slug), notice: "Your membership level for #{@band.name} has been updated."
  rescue StripeSubscriptionSwitcher::Error => e
    redirect_to public_band_path(@band.slug), alert: e.message
  end

  def set_band
    @band = Band.approved.find(params[:band_id])
  end

  def subscription_params
    params.require(:subscription).permit(:level)
  end
end
