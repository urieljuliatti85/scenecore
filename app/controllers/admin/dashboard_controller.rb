class Admin::DashboardController < Admin::BaseController
  DEFAULT_DAYS = 30

  def index
    @pending_bands_count = Band.pending.count
    @bands_count = Band.count
    @users_count = User.count

    @days = GoogleAnalyticsClient::ALLOWED_DAY_RANGES.include?(params[:days].to_i) ? params[:days].to_i : DEFAULT_DAYS
    @summary = google_analytics_summary
  end

  private

  # The dashboard's own counts come from the database and must render even
  # when Google Analytics is unreachable, so a reporting failure degrades to
  # a notice on the traffic section instead of taking the whole page down.
  def google_analytics_summary
    return nil unless GoogleAnalyticsClient.configured?

    GoogleAnalyticsClient.new.summary(days: @days)
  rescue GoogleAnalyticsClient::Error => e
    @analytics_error = e.message
    nil
  end
end
