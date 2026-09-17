# The band's own view of its Stripe Connect account: whether it can take
# money yet, and what is blocked until it can. Onboarding itself lives in
# StripeConnectAccountsController — this is the page that explains it and
# links to it.
class BandPaymentsController < ApplicationController
  before_action :set_band

  def show
    authorize @band, :update?, policy_class: BandPolicy

    @active_subscribers = @band.subscriptions.where(status: Subscription::BILLING_STATUSES).count
    @published_products = @band.products.published.count
  end

  private

  def set_band
    @band = Band.find(params[:band_id])
  end
end
