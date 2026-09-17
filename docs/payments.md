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

- **Subscriptions** (band memberships): plain Stripe Checkout Sessions
  against SceneCore's own Stripe account. No platform commission on this
  revenue today.
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

---

## Financial Rules

- Money is stored in integer cents.
- Platform commission must be explicit: 10% on Store orders, computed as
  `application_fee_amount` in the Stripe Connect destination charge and
  also recorded on the `Order` itself (`platform_fee_cents`) so it is
  auditable independent of Stripe's own records. Memberships carry a
  higher 25% commission (ADR-008), reflecting that the platform hosts and
  serves that relationship every month rather than settling a one-off
  sale. The membership split is decided but **not yet implemented** —
  subscriptions still charge SceneCore's own Stripe account, so no band
  payout happens today.
- Band revenue is explicit: for Store, the 90% remainder of a Connect
  destination charge, deposited directly to the band's connected Stripe
  account — SceneCore never custodies or manually redistributes it. For
  Subscriptions, 75% of the charge (ADR-008) — but today the full charge
  still lands in SceneCore's account, since the split has no
  implementation yet; closing that gap is outstanding work.
- Refund behavior: not yet defined for Store (open question — does a
  refund also reverse the platform's application fee, and who initiates
  it: the band from its connected account, or SceneCore on the band's
  behalf?). Needs its own decision before Store refunds are implemented.
- Payment provider is the source of payment status.