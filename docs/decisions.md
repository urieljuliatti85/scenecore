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

Store checkout (product purchases, ADR-003) uses Stripe Connect destination
charges through Checkout Sessions. Each band onboards a Stripe Connect
account; a Store checkout session's payment is split automatically at charge
time via `application_fee_amount`: 10% to SceneCore, the remaining 90% to
the band's connected account.

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
- ADR-008 supersedes the original subscription consequence: new
  subscriptions now split revenue 85/15 through Stripe Connect. Legacy
  subscriptions can be audited and migrated with the `subscriptions:unsplit`
  and `subscriptions:apply_split` tasks.
- Store destination-charge checkout completes on the platform webhook.
  `StripeWebhooksController` distinguishes Store and membership sessions by
  the persisted checkout session id, while connected-account
  `account.updated` events keep each band's onboarding status current.

---

## ADR-008 — Membership Revenue Split

Status: Accepted (2026-09-17)

### Decision

Membership revenue is split 85% to the band, 15% to SceneCore. This is the
decision ADR-007 anticipated when it recorded that splitting subscription
revenue would require its own ADR.

### Reason

Both rates are set against what comparable platforms charge, so a band
weighing SceneCore against the tools it already uses is not choosing
between a home and its income. 15% matches Bandcamp's artist
subscriptions; the Store's 10% (ADR-007) matches Bandcamp's physical
merchandise rate.

Memberships carry the higher of the two because the platform hosts and
serves that relationship every month — the exclusive feed, content,
community and messaging all run here — whereas a store sale is a one-off
transaction where the band supplies and ships the goods itself.

These are the platform's own rates and sit on top of Stripe's processing
fees, which matters at these price points: on a $3 Fan membership the
band's 85% is $2.55 before Stripe takes its share of the transaction.

### Consequence

- `docs/payments.md`'s rule that platform commission must be explicit now
  has a figure for memberships as well as for the Store.
- The public "How it works" page states both splits. It is the
  band-facing promise, so the page and this ADR must not drift apart.
- Implemented. New subscription Checkout Sessions set
  `application_fee_percent` and route the remainder to the band's active
  connected account. Bands without a payout-ready account cannot accept a
  membership payment. The `subscriptions:unsplit` and
  `subscriptions:apply_split` tasks cover subscriptions created before the
  split shipped.

---

## ADR-009 — Full Store Refunds Reverse Both Revenue Shares

Status: Accepted (2026-09-18)

### Decision

The Store supports full refunds only in the MVP. An administrator of the band
that owns the order initiates the refund through SceneCore. The platform creates
the Stripe refund for the destination charge with `reverse_transfer: true` and
`refund_application_fee: true`, so the fan receives the complete order total,
including shipping, while both the band's transfer and SceneCore's commission
are reversed.

The request records Stripe's refund identifier, but the order becomes
`refunded` only after a signed Stripe refund webhook reports success. A refund
does not restore product stock automatically.

### Reason

The platform created the destination charge and is therefore the reliable
place to coordinate all parts of its reversal. Keeping the application fee on
a sale that no longer exists would make the band absorb SceneCore's commission.
A full-only operation avoids ambiguous allocations across products, shipping,
and discounts in the first version.

Physical inventory cannot safely be inferred from a financial refund: a shipped
item may not have been returned, may arrive damaged, or may not be resellable.
The band must inspect the return before changing stock.

### Consequence

- Fans cannot issue an automatic refund; they contact the band.
- Platform administrators can inspect orders but do not act as a band's
  merchant by initiating this refund.
- Paid, processing, and completed orders are eligible. Pending, cancelled,
  already-refunded, or already-requested orders are not.
- Partial refunds, automatic returns, and automatic restocking remain outside
  the MVP.

---

## ADR-010 — Suspending a Band Cancels Its Fan Subscriptions

Status: Accepted (2026-09-23)

### Decision

Suspending a band (`BandsController#suspend`) cancels every fan subscription
still billing for it, in the same request. Each active or past-due
subscription goes through `SubscriptionCanceller` — the same path a fan
cancelling directly, or a platform administrator acting through
`/admin/memberships`, already uses — so Stripe stops charging and both the
Subscription and the Membership it granted are marked `cancelled`. One
subscription's Stripe call failing does not stop the rest from being
cancelled; the band is suspended either way, and the admin is told how many
subscriptions could not be reached.

Reactivating a band (`BandsController#reactivate`) does not reverse any of
this. No subscription is recreated or restored.

### Reason

Suspension takes a band's pages down immediately (`Band.approved` gates
every public route). Nothing else stopped Stripe from continuing to charge
fans for access the band no longer provides — an oversight found while
reviewing platform-admin privileges (see the scope changes in #213/#214).
Leaving billing running is the worst version of this gap: SceneCore would
keep processing payments on behalf of a band it suspended, potentially for
abuse or a policy violation.

`SubscriptionCanceller` and the underlying cancel semantics already existed
(`docs/database.md`, `Subscription.orphaned`) for exactly this shape of
problem — a subscription still billing without an active membership behind
it. This decision closes the one path that produced orphans without
anyone running `rake subscriptions:cancel_orphaned` to notice.

Reactivation does not restore subscriptions because a cancelled Stripe
subscription cannot be un-cancelled; recreating one means a new Checkout
Session, which only the fan can complete. Silently billing a fan again
without their action would be worse than requiring them to resubscribe.

### Consequence

- A suspended band has no fans billing for it once suspension completes.
- A fan who was subscribed loses access at the moment of suspension, not at
  the end of a billing period they already paid for.
- If a suspended band is reactivated, none of its former subscribers are
  automatically re-billed; each has to subscribe again if they still want
  in.
- `Subscription.orphaned` and the `subscriptions:orphaned`/
  `subscriptions:cancel_orphaned` rake tasks remain in place for
  subscriptions that fall out of sync some other way (their original
  purpose, predating this ADR).
