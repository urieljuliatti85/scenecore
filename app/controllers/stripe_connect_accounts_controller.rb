# Lets a band administrator start or resume Stripe Connect onboarding
# (ADR-007). There is nothing to "show" beyond the redirect itself — the
# account's live status is rendered wherever Band Admin already shows
# Store settings, driven by Band#stripe_connect_status.
class StripeConnectAccountsController < ApplicationController
  before_action :set_band

  def create
    start_onboarding
  end

  # Stripe's refresh_url: the previous onboarding link expired before the
  # band finished, so mint a new one and send them straight back in.
  def new
    start_onboarding
  end

  private

  def start_onboarding
    authorize @band, :update?, policy_class: BandPolicy

    url = StripeConnectOnboardingResolver.resolve(
      @band,
      contact_email: current_user.email,
      return_url: edit_band_url(@band),
      refresh_url: new_band_stripe_connect_account_url(@band)
    )

    redirect_to url, allow_other_host: true
  rescue StripeConnectOnboardingResolver::Error => e
    redirect_to edit_band_path(@band), alert: e.message
  end

  def set_band
    @band = Band.find(params[:band_id])
  end
end
