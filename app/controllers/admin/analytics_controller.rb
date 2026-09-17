class Admin::AnalyticsController < Admin::BaseController
  def show
    return unless GoogleAnalyticsClient.configured?

    @summary = GoogleAnalyticsClient.new.summary(days: 30)
  rescue GoogleAnalyticsClient::Error => e
    @error = e.message
  end
end
