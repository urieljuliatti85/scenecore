# Only configures Sentry when a DSN is present, so development, test and CI
# stay entirely offline — no accidental reporting, no network calls in specs.
# SENTRY_DSN is set as a Railway variable on the `web` service.
return if ENV["SENTRY_DSN"].blank?

Sentry.init do |config|
  config.dsn = ENV["SENTRY_DSN"]
  config.environment = Rails.env
  config.breadcrumbs_logger = [ :active_support_logger ]

  # Leave off by default: it attaches request bodies, cookies and user
  # details to events, which is exactly the data CLAUDE.md says not to ship
  # off-platform. Errors carry a stack trace and request path without it.
  config.send_default_pii = false

  # Bots and scanners hitting unknown paths are noise, not errors.
  config.excluded_exceptions += [
    "ActionController::RoutingError",
    "ActiveRecord::RecordNotFound"
  ]
end
