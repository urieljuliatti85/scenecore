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

  Metrics = Struct.new(:active_users, :sessions, :page_views, :top_pages, keyword_init: true)
  PageResult = Struct.new(:path, :views, keyword_init: true)

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

  # Summary totals plus the top pages by views, for the last `days` days.
  def summary(days: 30)
    raise Error, "Google Analytics is not configured" unless self.class.configured?

    date_range = Google::Analytics::Data::V1beta::DateRange.new(
      start_date: "#{days}daysAgo", end_date: "today"
    )

    totals = client.run_report(
      property: "properties/#{@property_id}",
      date_ranges: [ date_range ],
      metrics: [
        Google::Analytics::Data::V1beta::Metric.new(name: "activeUsers"),
        Google::Analytics::Data::V1beta::Metric.new(name: "sessions"),
        Google::Analytics::Data::V1beta::Metric.new(name: "screenPageViews")
      ]
    )

    pages = client.run_report(
      property: "properties/#{@property_id}",
      date_ranges: [ date_range ],
      dimensions: [ Google::Analytics::Data::V1beta::Dimension.new(name: "pagePath") ],
      metrics: [ Google::Analytics::Data::V1beta::Metric.new(name: "screenPageViews") ],
      order_bys: [ {
        metric: { metric_name: "screenPageViews" },
        desc: true
      } ],
      limit: 10
    )

    row = totals.rows.first
    Metrics.new(
      active_users: row&.metric_values&.[](0)&.value.to_i,
      sessions: row&.metric_values&.[](1)&.value.to_i,
      page_views: row&.metric_values&.[](2)&.value.to_i,
      top_pages: pages.rows.map { |r| PageResult.new(path: r.dimension_values[0].value, views: r.metric_values[0].value.to_i) }
    )
  rescue Google::Cloud::Error, ::GRPC::BadStatus, Signet::AuthorizationError => e
    raise Error, "Could not reach Google Analytics: #{e.message}"
  end

  private

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
