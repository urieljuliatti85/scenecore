# Architecture

## 1. Architecture Style

Rails monolith.

The application uses:

- Ruby on Rails (8.1)
- PostgreSQL
- Propshaft (asset pipeline)
- Importmap (JavaScript, no Node bundler)
- Hotwire (Turbo + Stimulus)
- Tailwind CSS
- Active Storage
- Solid Queue / Solid Cache / Solid Cable (database-backed jobs,
  cache, and websockets — Rails 8 defaults, no Redis dependency)
- Puma (web server) + Thruster
- Kamal (Docker-based deploys — present from `rails new`, not yet
  configured for a real target; see `docs/deployment.md`)

---

## 2. Architectural Principles

- Prefer Rails conventions.
- Keep controllers thin.
- Prefer models for domain behavior.
- Use service objects for complex workflows.
- Avoid premature abstractions.
- Avoid unnecessary APIs.
- PostgreSQL is the source of truth.

---

## 3. Main Domains

### Identity

Responsible for:

- users
- authentication
- sessions

### Bands

Responsible for:

- bands
- memberships
- administrators

### Music

Responsible for:

- releases
- tracks
- audio

### Content

Responsible for:

- posts
- exclusive content
- visibility

### Commerce

Responsible for:

- products
- cart
- orders
- payments

### Subscriptions

Responsible for:

- plans
- subscriptions
- billing

### Events

Responsible for:

- events
- tickets
- check-in

---

## 4. Application Structure

Controllers:

app/controllers/

Models:

app/models/

Services:

app/services/ (Stripe, Spotify, and Google Analytics integrations,
plus RemoteImageFetcher — see §5)

Jobs:

app/jobs/

Policies:

app/policies/ (Pundit, one policy per model — see CLAUDE.md)

---

## 5. External Services

### Stripe

- Purpose: subscription billing for band memberships and Store checkout,
  including Stripe Connect onboarding and revenue splits.
- Authentication: server-to-server via a secret key
  (`Rails.application.credentials.dig(:stripe, :secret_key)`), wrapped
  in `StripeClient.instance` (a configured `Stripe::StripeClient`, not
  the deprecated global `Stripe.api_key =` pattern). No user-level
  OAuth.
- API: Stripe Checkout Sessions (`StripeCheckoutCompletedHandler`,
  `StripeStorePaymentHandler`, `StoreCheckoutSessionCreator`,
  `StoreOrderRefundCreator`, `StripeStoreRefundHandler`,
  `StripeCustomerResolver`, `StripePriceResolver`), Connect onboarding,
  and the Subscriptions API (`StripeSubscriptionSwitcher` for plan
  changes). Membership payments split 85/15 and Store payments split
  90/10 through the band's connected account.
- Webhooks: `StripeWebhooksController` (`POST /stripe/webhooks`, no
  session/CSRF — Stripe calls this directly). Authenticity is verified
  via `Stripe::Webhook.construct_event` against the
  `Stripe-Signature` header and the configured endpoint secret; an
  unverifiable payload gets `400` and nothing is processed. Handled
  event types: `checkout.session.completed`,
  `customer.subscription.updated`, `customer.subscription.deleted`,
  `refund.created`, `refund.updated`, `refund.failed`, and connected-account
  `account.updated`. A completed checkout is dispatched to the Store or
  membership handler by its persisted session id. Store refund events use
  the persisted refund id (with order metadata as the race-safe fallback)
  and only a successful Stripe event marks the order refunded.
  Idempotency: `StripeWebhookEvent.record!` uniquely constrains on
  `stripe_event_id` before any handler runs, so a redelivered event
  (Stripe's own retry policy, or a duplicate send) is recognized and
  answered with `200 OK` without reprocessing.
- Failure behavior: an unverifiable signature or unparsable payload
  returns `400` so Stripe's own retry/alerting takes over. Once
  verified, a duplicate event is swallowed (see idempotency above)
  rather than erroring. There is no separate reconciliation job —
  webhooks are the single source of payment-state truth.

### Spotify

- Purpose: catalog search and metadata lookup when a band creates an
  album (search-and-import flow); SceneCore never hosts or streams
  Spotify audio, only links out to it.
- Authentication: OAuth 2.0 Client Credentials flow (no user login) via
  `Rails.application.credentials.spotify`. The access token is cached
  in `Rails.cache` for 50 minutes (`SpotifyClient::TOKEN_CACHE_KEY`),
  just under Spotify's token lifetime, so a token is requested at most
  once per cache window rather than per request.
- API: Spotify Web API's `/search` (albums) and `/albums/:id` read-only
  endpoints, called with `Net::HTTP` directly (no SDK).
- Webhooks: none — Spotify does not push data to SceneCore.
- Failure behavior: connection-level failures (timeouts, DNS, TLS,
  connection reset) and non-2xx/unparsable responses are all normalized
  into `SpotifyClient::Error`, so a Spotify outage surfaces as a
  handled error to the caller (e.g. "search unavailable") instead of an
  unhandled exception or a request hang — request/read timeouts are
  deliberately short (3s/5s) so one slow Spotify call can't tie up a
  Puma thread.

### Google Analytics (GA4 Data API)

- Purpose: traffic reporting (active users, sessions, page views, top
  pages, daily trend, traffic channels, device mix) surfaced on the
  platform admin dashboard. Client-side page tracking itself is the
  `gtag.js` snippet in the layout `<head>`, gated by the site's cookie
  consent banner (GA4 Consent Mode: `analytics_storage` defaults to
  `denied`, granted only after consent).
- Authentication: a GA4 service account with read-only ("Viewer")
  access on the property — server-to-server, no user OAuth, the same
  shape as Spotify's Client Credentials flow. Credentials are read from
  either a gitignored local file
  (`config/google_analytics_credentials.json`) or, where a host can't
  mount files as secrets (Railway), a `GOOGLE_ANALYTICS_CREDENTIALS_JSON`
  env var holding the same JSON key content
  (`GoogleAnalyticsClient.credentials_source`).
- API: Google Analytics Data API v1beta (`runReport`), called through
  the `google-analytics-data` gem. `GoogleAnalyticsClient#summary`
  restricts requests to 3 fixed day ranges (7/30/90 —
  `ALLOWED_DAY_RANGES`) since it only backs the admin UI's preset
  buttons, not a free-form report builder.
- Webhooks: none.
- Failure behavior: `GoogleAnalyticsClient.configured?` lets the admin
  view detect a missing property ID or credentials and render a
  "not configured" state instead of erroring. Once configured,
  API-level failures (`Google::Cloud::Error`, `GRPC::BadStatus`,
  `Signet::AuthorizationError`) are caught and re-raised as
  `GoogleAnalyticsClient::Error`, so a GA outage or auth problem
  surfaces as a handled admin-page error rather than a 500.

### Remote image fetching (album cover import)

Not a third-party API integration in the usual sense — no vendor,
no credentials — but it is an external-network call worth documenting
here because of its SSRF exposure: `RemoteImageFetcher` downloads a
user-supplied image URL (e.g. pulled alongside a Bandcamp/Spotify
import) so it can be attached as an album cover.

- Purpose: let a band set an album cover from an external image URL
  without asking them to re-upload a file.
- Authentication: none — fetches a public URL.
- API: plain HTTP(S) GET via `Net::HTTP`, no client library.
- Webhooks: none.
- Failure behavior: hardened against SSRF — only `http`/`https` are
  accepted, the resolved IP is checked (and re-checked on every
  redirect, capped at `MAX_REDIRECTS`) to reject loopback/private/
  link-local addresses, the response must match an allowed image
  content type, and the body is truncated mid-stream once it exceeds
  `HasImage::IMAGE_MAX_SIZE` rather than buffered unbounded. Any
  failure (unreachable host, disallowed type, oversized body, too many
  redirects) is normalized into `RemoteImageFetcher::Error` and shown
  to the band as a plain validation message.
