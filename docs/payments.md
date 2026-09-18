# Payments

## Scope

Payments support:

- one-time purchases
- subscriptions
- Pix
- credit card
- refunds
- chargebacks

## Provider

Stripe (already integrated — see `docs/architecture.md` §5). Two distinct
flows exist:

- **Subscriptions** (band memberships, ADR-008): Stripe Checkout Sessions
  create subscriptions with `application_fee_percent` and
  `transfer_data`, so SceneCore's 15% commission and the band's 85% are
  split on every invoice. The band must have an active connected account
  before it can accept a subscription.
- **Store** (product purchases, ADR-007): Stripe Connect. Each band has
  its own connected Stripe account; checkout uses a destination charge
  with `application_fee_amount` so SceneCore's 10% commission and the
  band's 90% are split automatically in the same payment. A band must
  complete Stripe Connect onboarding (handled by Stripe's own hosted
  flow) before its Store can accept checkout.

---

## Payment States

pending
authorized
paid
failed
cancelled
refunded
partially_refunded

---

## Order States

pending
paid
processing
completed
cancelled
refunded

---

## Subscription States

pending
active
past_due
cancelled
expired

---

## Webhooks

All payment webhooks must:

- validate authenticity;
- be idempotent;
- persist the external event ID;
- handle duplicate events;
- handle out-of-order events;
- log enough information for debugging;
- never expose secrets.

The single Stripe event destination accepts both v1 snapshot events and
Accounts v2 thin notifications. Accounts v2 connected accounts created by the
platform report recipient readiness through
`v2.core.account[configuration.recipient].capability_status_updated`; the thin
payload is signature-verified, then SceneCore fetches the account's current
state before changing local payment readiness.

---

## Financial Rules

- Money is stored in integer cents.
- Platform commission must be explicit: 10% on Store orders, computed as
  `application_fee_amount` in the Stripe Connect destination charge and
  also recorded on the `Order` itself (`platform_fee_cents`) so it is
  auditable independent of Stripe's own records. Memberships carry 15%
  (ADR-008) — higher than the Store's 10%, since the platform hosts and
  serves that relationship every month rather than settling a one-off
  sale. Applied as `application_fee_percent` on the Stripe subscription,
  so every monthly charge splits at source.
- Band revenue is explicit: for Store, the 90% remainder of a Connect
  destination charge, deposited directly to the band's connected Stripe
  account — SceneCore never custodies or manually redistributes it.
  Memberships are 85% to the band on the same basis. Subscriptions
  created before that split was implemented still charge the full amount
  to SceneCore — `rake subscriptions:unsplit` lists them and
  `rake subscriptions:apply_split` routes them to their band from the
  next invoice.
- `PlatformSetting#membership_fee_percentage` and
  `PlatformSetting#store_fee_percentage` are admin-editable, defaulting to
  15% and 10% respectively. Subscription checkout reads the membership
  rate and Store checkout records and sends the Store rate to Stripe.
- A Band Administrator can read the connected account's available and pending
  balances and its next pending payout from Band Admin. Every request is
  scoped to that band's Stripe account, and a Stripe outage degrades the
  summary instead of blocking the panel. Opening the financial dashboard
  creates a fresh single-use Stripe Express login link after the same
  band-scoped authorization check; SceneCore does not store that link and
  cannot move funds or change bank details.
- Store refunds are full-only in the MVP and are initiated in SceneCore by
  an administrator of the band that owns the order. SceneCore creates the
  Stripe refund on the destination charge with both `reverse_transfer` and
  `refund_application_fee`, returning the full item and shipping amount to
  the fan while reversing the band's transfer and the platform commission
  (ADR-009). The order becomes `refunded` only after a signed Stripe refund
  webhook confirms success. Refunding never restores inventory
  automatically; the band adjusts stock after physically receiving any
  returned goods.
- Payment provider is the source of payment status.
