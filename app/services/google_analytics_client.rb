require "google/analytics/data"
require "google/analytics/data/v1beta"
require "google-cloud-errors"
require "grpc"
require "googleauth"

# Reads traffic reports from the Google Analytics Data API for the
# platform admin dashboard. Uses a service account (read-only "Viewer"
# access on the GA4 property) rather than OAuth, since no human needs to
# authorize this — it's a server-to-server report pull, the same shape as
# SpotifyClient's Client Credentials flow.
class GoogleAnalyticsClient
  Error = Class.new(StandardError)

  CREDENTIALS_PATH = Rails.root.join("config/google_analytics_credentials.json")
  ALLOWED_DAY_RANGES = [ 7, 30, 90 ].freeze

  Metrics = Struct.new(
    :active_users, :sessions, :page_views, :bounce_rate, :session_duration,
    :top_pages, :landing_pages, :daily_series, :channels, :devices,
    keyword_init: true
  )
  # bounce_rate is a fraction (0.0–1.0) as GA4 returns it; the view formats
  # it. avg_duration and avg_time_on_page are seconds.
  PageResult = Struct.new(:path, :views, :bounce_rate, :avg_duration, :avg_time_on_page, keyword_init: true)
  LandingPageResult = Struct.new(:path, :users, :bounce_rate, :avg_duration, :avg_time_on_page, keyword_init: true)
  DailyPoint = Struct.new(:date, :active_users, :sessions, :bounce_rate, keyword_init: true)
  BreakdownResult = Struct.new(:label, :sessions, keyword_init: true)

  # Local dev keeps the key as a file (gitignored); hosts that can't mount
  # a file as a secret (e.g. Railway) set GOOGLE_ANALYTICS_CREDENTIALS_JSON
  # to the key's raw JSON content as an env var instead. Either is enough.
  def self.configured?
    ENV["GOOGLE_ANALYTICS_PROPERTY_ID"].present? && credentials_source.present?
  end

  def self.credentials_source
    ENV["GOOGLE_ANALYTICS_CREDENTIALS_JSON"].presence || (CREDENTIALS_PATH.to_s if CREDENTIALS_PATH.exist?)
  end

  def initialize
    @property_id = ENV["GOOGLE_ANALYTICS_PROPERTY_ID"]
  end

  # Totals, daily trend, top pages, traffic channel, and device breakdown
  # for the last `days` days. `days` is restricted to ALLOWED_DAY_RANGES
  # rather than accepting anything, since this only ever backs the three
  # preset buttons in the admin UI — not a free-form report builder.
  def summary(days: 30)
    raise Error, "Google Analytics is not configured" unless self.class.configured?
    raise Error, "Unsupported day range: #{days}" unless ALLOWED_DAY_RANGES.include?(days)

    date_range = Google::Analytics::Data::V1beta::DateRange.new(
      start_date: "#{days}daysAgo", end_date: "today"
    )

    Metrics.new(
      **totals(date_range),
      top_pages: top_pages(date_range),
      landing_pages: landing_pages(date_range),
      daily_series: daily_series(date_range),
      channels: channel_breakdown(date_range),
      devices: device_breakdown(date_range)
    )
  rescue Google::Cloud::Error, ::GRPC::BadStatus, Signet::AuthorizationError => e
    raise Error, "Could not reach Google Analytics: #{e.message}"
  end

  private

  def totals(date_range)
    report = client.run_report(
      property: "properties/#{@property_id}",
      date_ranges: [ date_range ],
      metrics: [
        Google::Analytics::Data::V1beta::Metric.new(name: "activeUsers"),
        Google::Analytics::Data::V1beta::Metric.new(name: "sessions"),
        Google::Analytics::Data::V1beta::Metric.new(name: "screenPageViews"),
        Google::Analytics::Data::V1beta::Metric.new(name: "bounceRate"),
        Google::Analytics::Data::V1beta::Metric.new(name: "averageSessionDuration")
      ]
    )

    row = report.rows.first
    {
      active_users: row&.metric_values&.[](0)&.value.to_i,
      sessions: row&.metric_values&.[](1)&.value.to_i,
      page_views: row&.metric_values&.[](2)&.value.to_i,
      bounce_rate: row&.metric_values&.[](3)&.value.to_f,
      session_duration: row&.metric_values&.[](4)&.value.to_f
    }
  end

  def top_pages(date_range)
    report = client.run_report(
      property: "properties/#{@property_id}",
      date_ranges: [ date_range ],
      dimensions: [ Google::Analytics::Data::V1beta::Dimension.new(name: "pagePath") ],
      metrics: [
        Google::Analytics::Data::V1beta::Metric.new(name: "screenPageViews"),
        Google::Analytics::Data::V1beta::Metric.new(name: "bounceRate"),
        Google::Analytics::Data::V1beta::Metric.new(name: "averageSessionDuration"),
        Google::Analytics::Data::V1beta::Metric.new(name: "userEngagementDuration")
      ],
      order_bys: [ { metric: { metric_name: "screenPageViews" }, desc: true } ],
      limit: 10
    )

    report.rows.map do |r|
      PageResult.new(
        path: r.dimension_values[0].value,
        views: r.metric_values[0].value.to_i,
        bounce_rate: r.metric_values[1].value.to_f,
        avg_duration: r.metric_values[2].value.to_f,
        # userEngagementDuration is the total across views, so divide it
        # back out to get the per-view average the table column means.
        avg_time_on_page: r.metric_values[0].value.to_i.positive? ? r.metric_values[3].value.to_f / r.metric_values[0].value.to_i : 0
      )
    end
  end

  # GA4's landingPage dimension answers "where did people arrive", which is
  # a different question from "which pages got viewed" above — a page can
  # be heavily viewed without ever being an entry point.
  def landing_pages(date_range)
    report = client.run_report(
      property: "properties/#{@property_id}",
      date_ranges: [ date_range ],
      dimensions: [ Google::Analytics::Data::V1beta::Dimension.new(name: "landingPage") ],
      metrics: [
        Google::Analytics::Data::V1beta::Metric.new(name: "activeUsers"),
        Google::Analytics::Data::V1beta::Metric.new(name: "bounceRate"),
        Google::Analytics::Data::V1beta::Metric.new(name: "averageSessionDuration"),
        Google::Analytics::Data::V1beta::Metric.new(name: "userEngagementDuration"),
        Google::Analytics::Data::V1beta::Metric.new(name: "screenPageViews")
      ],
      order_bys: [ { metric: { metric_name: "activeUsers" }, desc: true } ],
      limit: 10
    )

    report.rows.map do |r|
      views = r.metric_values[4].value.to_i
      LandingPageResult.new(
        path: r.dimension_values[0].value,
        users: r.metric_values[0].value.to_i,
        bounce_rate: r.metric_values[1].value.to_f,
        avg_duration: r.metric_values[2].value.to_f,
        avg_time_on_page: views.positive? ? r.metric_values[3].value.to_f / views : 0
      )
    end
  end

  # One point per calendar day, carrying bounce rate alongside the counts so
  # the dashboard can plot users against bounce rate on one chart.
  def daily_series(date_range)
    report = client.run_report(
      property: "properties/#{@property_id}",
      date_ranges: [ date_range ],
      dimensions: [ Google::Analytics::Data::V1beta::Dimension.new(name: "date") ],
      metrics: [
        Google::Analytics::Data::V1beta::Metric.new(name: "activeUsers"),
        Google::Analytics::Data::V1beta::Metric.new(name: "sessions"),
        Google::Analytics::Data::V1beta::Metric.new(name: "bounceRate")
      ],
      order_bys: [ { dimension: { dimension_name: "date" } } ]
    )

    report.rows.map do |r|
      DailyPoint.new(
        date: Date.strptime(r.dimension_values[0].value, "%Y%m%d"),
        active_users: r.metric_values[0].value.to_i,
        sessions: r.metric_values[1].value.to_i,
        bounce_rate: r.metric_values[2].value.to_f
      )
    end
  end

  # GA4's own channel grouping (Organic Search, Direct, Social, Referral,
  # etc.) rather than raw source/medium — that's the level of detail a
  # "where do visitors come from" admin view needs, not a full attribution
  # report.
  def channel_breakdown(date_range)
    breakdown_report("sessionDefaultChannelGroup", date_range)
  end

  def device_breakdown(date_range)
    breakdown_report("deviceCategory", date_range)
  end

  def breakdown_report(dimension_name, date_range)
    report = client.run_report(
      property: "properties/#{@property_id}",
      date_ranges: [ date_range ],
      dimensions: [ Google::Analytics::Data::V1beta::Dimension.new(name: dimension_name) ],
      metrics: [ Google::Analytics::Data::V1beta::Metric.new(name: "sessions") ],
      order_bys: [ { metric: { metric_name: "sessions" }, desc: true } ]
    )

    report.rows.map { |r| BreakdownResult.new(label: r.dimension_values[0].value, sessions: r.metric_values[0].value.to_i) }
  end

  def client
    @client ||= Google::Analytics::Data.analytics_data do |config|
      config.credentials = credentials
    end
  end

  # A file path can go straight into config.credentials, but a raw JSON
  # string (from ENV, since Railway can't mount a file as a secret) has to
  # be built into an actual credentials object first — config.credentials=
  # only accepts a path string or an already-constructed credentials
  # instance, not a JSON string or IO.
  def credentials
    source = self.class.credentials_source
    return source unless source.start_with?("{")

    Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: StringIO.new(source),
      scope: "https://www.googleapis.com/auth/analytics.readonly"
    )
  end
end
