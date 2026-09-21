class Admin::FinancialStatusController < Admin::BaseController
  def show
    @stripe_status = StripePlatformStatus.call(webhook_url: stripe_webhooks_url)
    @stripe_connect_counts = Band.approved.group(:stripe_connect_status).count
    stripe_action_required = Band.approved.where.not(stripe_connect_status: :active)
    @stripe_pending_bands_count = stripe_action_required.count
    @stripe_pending_bands = stripe_action_required.order(updated_at: :desc).limit(8)
  end
end
