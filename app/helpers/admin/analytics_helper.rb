module Admin::AnalyticsHelper
  # GA4 reports durations in seconds. Anything under a minute reads better
  # as plain seconds ("47 s") than as "0:47", which is how the dashboard's
  # session and time-on-page columns are meant to be read.
  def analytics_duration(seconds)
    seconds = seconds.to_i
    return "#{seconds} s" if seconds < 60

    minutes, remainder = seconds.divmod(60)
    "#{minutes}m #{remainder}s"
  end

  # GA4 omits a metric entirely when it has nothing to report for the
  # period, so a rate can arrive nil rather than zero.
  def analytics_percentage(rate)
    number_to_percentage(rate.to_f * 100, precision: 0)
  end
end
