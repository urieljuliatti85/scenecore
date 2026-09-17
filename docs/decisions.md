# Architecture Decisions

## ADR-001 — Rails Monolith

Status: Accepted

### Decision

The MVP will use a Rails monolith.

### Reason

The MVP does not justify microservices.

### Consequence

Domain boundaries should exist inside the monolith.

---

## ADR-002 — PostgreSQL

Status: Accepted

### Decision

PostgreSQL is the source of truth.

### Reason

The application requires relational data,
transactions and strong consistency.

---

## ADR-003 — Single-band Cart

Status: Accepted

### Decision

An order/cart can contain products from only one band.

### Reason

Simplifies checkout, fulfillment and revenue allocation
for the MVP.

---

## ADR-004 — Server-side Authorization

Status: Accepted

### Decision

All private resources must be authorized server-side.

### Reason

Frontend restrictions are not security boundaries.

---

## ADR-005 — Music-first Band Home Positioning

Status: Accepted

### Decision

SceneCore is positioned as a music-first digital home for the ongoing
relationship between an independent band and its fans.

SceneCore complements discovery, streaming, commerce, and membership platforms;
it does not require bands to replace Spotify, Bandcamp, Patreon, or equivalent
channels.

“The scene” is a future strategic opportunity, not part of the current MVP
unless separately validated and approved.

### Reason

“Everything for bands in one place” is generic and does not distinguish
SceneCore from existing products. Centering the persistent band–fan relationship
provides a clearer product outcome while keeping music at the core.

### Consequence

Product and UX decisions should strengthen the band's home and the fan's return
relationship. Competitor parity and feature count are not sufficient reasons to
expand scope. Scene-level social or discovery features must remain proposals
until explicitly approved.

---

## ADR-006 — Retained Followers as Primary MVP Metric

Status: Accepted

### Decision

The primary MVP metric is retained followers: the percentage of a band's
followers still following after 30 days.

Once Phase 10 (Subscriptions) ships, subscription retention (percentage of
subscribers still active after N billing cycles) should supersede it as the
primary metric.

### Reason

The product promise is an *ongoing* band–fan relationship, not a single
transaction or a low-friction action like following. Retention over a fixed
window is measurable today with the existing Follow model (Phase 6) and
approximates durability without depending on unbuilt features (Store,
Payments, Events). Subscription retention is a stronger signal once
recurring paid relationships exist.

### Consequence

Product decisions in the MVP should be evaluated in part against whether
they improve follower retention, not just raw follow or signup counts.
Analytics/reporting for this metric is not yet built and is not implied by
this decision.

---

## ADR-007 — Stripe Connect for Store Revenue Split

Status: Accepted (2026-09-17)

### Decision

Store checkout (product purchases, ADR-003) uses Stripe Connect, not the
plain Stripe Checkout Sessions already used for Subscriptions. Each band
onboards a Stripe Connect account; a Store checkout session's payment is
split automatically at charge time via `application_fee_amount`: 10% to
SceneCore, the remaining 90% to the band's connected account.

### Reason

A store sells one band's physical/digital goods directly to a fan; the
platform's 10% commission on that sale must be explicit per
`docs/payments.md` and must not require a manual reconciliation process.
Stripe Connect's destination charges compute and route both sides of the
split within the same payment, so SceneCore never holds funds it must
later redistribute, and there is nothing new to reconcile beyond what
Stripe's own dashboard/reports already provide the band.

### Consequence

- A `Band` needs a `stripe_connect_account_id` and an onboarding status
  (not yet started / onboarding / active / restricted) before it can sell
  products; a band cannot open a Store checkout until its connected
  account is active (Stripe's own capability checks, surfaced to the band
  in Band Admin).
- Subscriptions (ADR/Phase 10) are unaffected — they keep using the
  existing plain Stripe Checkout Sessions and SceneCore's own Stripe
  account; no commission split exists on subscription revenue today and
  this decision does not introduce one retroactively. A future decision
  to also split subscription revenue would need its own ADR.
- Store's Stripe webhooks must handle events under the connected account
  (Stripe sends these with an `account` field identifying which connected
  account they belong to) in addition to the platform-account events
  Subscriptions already handles — `StripeWebhooksController` must
  distinguish the two rather than assuming every webhook is
  platform-level.
