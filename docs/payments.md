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
- `PlatformSetting#platform_fee_percentage` exists as an admin-editable
  override and currently reads 0. Nothing consumes it yet — no checkout
  computes a fee from it — so the rates above are documented figures, not
  values the running system applies. It also holds a single percentage
  while there are now two rates, so it cannot express both. Resolve that
  when Store checkout is built rather than leaving them disagreeing.
  disagreeing.
- Refund behavior: not yet defined for Store (open question — does a
  refund also reverse the platform's application fee, and who initiates
  it: the band from its connected account, or SceneCore on the band's
  behalf?). Needs its own decision before Store refunds are implemented.
- Payment provider is the source of payment status.