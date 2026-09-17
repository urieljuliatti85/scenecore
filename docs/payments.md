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
  with `application_fee_amount` so SceneCore's 25% commission and the
  band's 75% are split automatically in the same payment. A band must
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
- Platform commission must be explicit: 25% on Store orders, computed as
  `application_fee_amount` in the Stripe Connect destination charge and
  also recorded on the `Order` itself (`platform_fee_cents`) so it is
  auditable independent of Stripe's own records. Memberships carry the
  same 25% (ADR-008), so a band earns the same share whichever way a fan
  supports it. The membership split is decided but **not yet
  implemented** — subscriptions still charge SceneCore's own Stripe
  account, so no band payout happens today.
- Band revenue is explicit: for Store, the 75% remainder of a Connect
  destination charge, deposited directly to the band's connected Stripe
  account — SceneCore never custodies or manually redistributes it.
  Memberships are 75% to the band on the same basis, though today the
  full charge still lands in SceneCore's account; closing that gap is
  outstanding work.
- `PlatformSetting#platform_fee_percentage` exists as an admin-editable
  override and currently reads 0. Nothing consumes it yet — no checkout
  computes a fee from it — so 25% above is the documented rate, not a
  value the running system applies. Whichever of the two becomes
  authoritative when Store checkout is built, they must not be left
  disagreeing.
- Refund behavior: not yet defined for Store (open question — does a
  refund also reverse the platform's application fee, and who initiates
  it: the band from its connected account, or SceneCore on the band's
  behalf?). Needs its own decision before Store refunds are implemented.
- Payment provider is the source of payment status.