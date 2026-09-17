# The band's own view of its Stripe Connect account: whether it can take
# money yet, and what is blocked until it can. Onboarding itself lives in
# StripeConnectAccountsController — this is the page that explains it and
# links to it.
class BandPaymentsController < ApplicationController
  before_action :set_band

  def show
    authorize @band, :update?, policy_class: BandPolicy

    refresh_connect_status if @band.stripe_connect_onboarding?

    @active_subscribers = @band.subscriptions.where(status: Subscription::BILLING_STATUSES).count
    @published_products = @band.products.published.count
  end

  private

  # Status normally arrives by webhook. A webhook that never lands would
  # otherwise strand the band here forever, so opening this page while
  # mid-onboarding asks Stripe directly — the one state where the answer is
  # expected to change and the band is actively waiting on it.
  #
  # A failure here is not shown: the page's own job is to report what is
  # blocked, and it can still do that from the status already stored.
  def refresh_connect_status
    StripeConnectStatusRefresher.call(@band)
    @band.reload
  rescue StripeConnectStatusRefresher::Error => e
    Rails.logger.warn("Could not refresh Stripe Connect status for band #{@band.id}: #{e.message}")
  end

  def set_band
    @band = Band.find(params[:band_id])
  end
end
