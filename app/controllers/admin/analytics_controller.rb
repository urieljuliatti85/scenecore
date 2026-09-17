class Admin::AnalyticsController < Admin::BaseController
  def show
    @days = GoogleAnalyticsClient::ALLOWED_DAY_RANGES.include?(params[:days].to_i) ? params[:days].to_i : 30

    return unless GoogleAnalyticsClient.configured?

    @summary = GoogleAnalyticsClient.new.summary(days: @days)
  rescue GoogleAnalyticsClient::Error => e
    @error = e.message
  end
end
