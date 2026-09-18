# Database

## Users

### Purpose

Represents a platform user.

### Attributes

- id
- email
- name
- created_at
- updated_at

---

## Bands

### Purpose

Represents a musical project.

### Attributes

- id
- name
- slug
- description
- status
- created_at
- updated_at

---

## BandMemberships

### Purpose

Connects users and bands.

### Attributes

- user_id
- band_id
- role

### Rules

- A user may belong to multiple bands.
- A band may have multiple members.
- A band may have multiple administrators.

---

## Albums

### Purpose

A band's release, shown as cover and title and linking out to Spotify for
listening.

### Attributes

- band_id
- title
- status
- cover
- spotify_id
- spotify_cover_url
- created_at
- updated_at

### Rules

- An album belongs to one band.
- An album is a pointer to Spotify, not a track listing. SceneCore stores
  the album's Spotify id at import and derives the listen link from it;
  it does not mirror the album's tracks.
- Draft albums are not publicly accessible.
- Published albums may be publicly accessible.

---

## Tracks

**Superseded 2026-09-16.** Albums link out to Spotify instead of
mirroring its catalogue, so nothing creates, reads or renders a track any
more.

The table and model are deliberately kept for now: they still hold the
rows imported under the old behaviour, and dropping them would be an
irreversible migration for a decision only days old. Remove both once the
new shape has settled.

The previous rules were: a track belonged to one album (and through it to
one band); its audio was never hosted by SceneCore but linked to the
corresponding Spotify track, played through Spotify's embed; draft tracks
were not publicly accessible and published ones could be.

---

## Products

### Purpose

A band's sellable item (merch, physical or digital) shown in its Store.

### Attributes

- id
- band_id
- name
- description
- status (draft/published — same gating pattern as Albums/Posts)
- created_at
- updated_at

### Rules

- A product belongs to one band.
- A product has one or more variants (`ProductVariants`); a product with
  no size/color options still has exactly one variant (e.g. "Default"),
  so price and stock always live on the variant, never on the product
  itself — no separate "simple product" code path.
- Draft products are not publicly accessible, same visibility gating as
  Albums/Posts.

---

## ProductVariants

### Purpose

One purchasable SKU of a product (e.g. "T-shirt — M — Black").

### Attributes

- id
- product_id
- sku (unique)
- name (e.g. "M / Black")
- price_cents
- stock_quantity
- created_at
- updated_at

### Rules

- A variant belongs to one product.
- Price and stock are per variant, not per product — two variants of the
  same product may have different prices (e.g. a limited color costs
  more) and independent stock counts.
- `stock_quantity` must never go negative. Decrementing stock on purchase
  and the variant's own row must be guarded against two concurrent
  purchases both reading the same pre-decrement count (row-level lock or
  an equivalent atomic update — decided at implementation time, not a
  product decision).
- A variant with `stock_quantity` 0 is shown as sold out, not hidden —
  same "don't silently hide the existence of content" principle already
  applied to locked content (`docs/product.md` §3 Journey 2/6 discussion).

---

## Carts

### Purpose

A fan's in-progress selection of variants from one band's Store, prior to
checkout.

### Attributes

- id
- user_id
- band_id
- status (active/converted/abandoned)
- created_at
- updated_at

### Rules

- A user has at most one `active` cart at a time, across the whole
  platform (not per band) — ADR-003 already required a cart to hold only
  one band's products; this adds that a second, parallel active cart with
  a *different* band cannot coexist. Adding a product from a different
  band while an active cart exists must either be blocked (surfaced to
  the fan) or replace/clear the current cart — the exact UX is an
  implementation-time decision, not a data-model one, but the invariant
  "at most one active cart per user" is enforced at the database level
  (unique partial index on `user_id` where `status = 'active'`).
- A cart converts to exactly one Order at checkout and is not reused
  afterward (`status` becomes `converted`).

---

## CartItems

### Purpose

One line item inside a Cart: a variant and a quantity.

### Attributes

- id
- cart_id
- product_variant_id
- quantity
- created_at
- updated_at

### Rules

- A cart item's `product_variant_id` must belong to the same band as the
  cart's `band_id` (enforced at the model/service layer, not just
  assumed).
- Quantity must be a positive integer and is checked against the
  variant's current `stock_quantity` both when added to the cart and
  again at checkout (stock can change between the two).

---

## Orders

### Purpose

A completed or in-progress purchase of one band's products by one fan.

### Attributes

- id
- user_id
- band_id
- status (pending/paid/processing/completed/cancelled/refunded —
  `docs/payments.md` Order States)
- subtotal_cents
- shipping_cents
- total_cents
- platform_fee_cents (10% of subtotal, per ADR-007 — recorded on the
  order even though Stripe Connect computes the actual split, so the
  band's payout is auditable independent of Stripe's own records)
- stripe_checkout_session_id
- stripe_payment_intent_id
- stripe_refund_id
- refund_status (pending/requires_action/succeeded/failed/canceled, nullable
  until a refund is requested)
- refunded_at
- created_at
- updated_at

### Rules

- An order belongs to one band in the MVP (ADR-003).
- Monetary values are stored in cents.
- Order state must be explicit and, once payment-related, driven by
  Stripe webhooks as the source of truth (`docs/payments.md`), not
  inferred client-side.
- A Store order can receive at most one full refund request in the MVP.
  `stripe_refund_id` makes that request auditable and unique; the order does
  not enter `refunded` until Stripe confirms a successful refund by webhook.
- Refunds do not change ProductVariant stock. A band adjusts stock manually
  after it has physically received a returned product.
- An order is created from a Cart at checkout; it snapshots each item's
  product name, variant name, and price at that moment (`OrderItems`,
  below) so later edits to the product/variant never change a past
  order's recorded price or description.
- An order has exactly one `ShippingAddress` (`has_one`, the foreign key
  lives on `shipping_addresses.order_id` — see below), required since
  Store ships physical goods in this version; there is no digital-
  delivery/no-shipping order type yet.

---

## OrderItems

### Purpose

A frozen snapshot of one Cart item at the moment an Order was placed.

### Attributes

- id
- order_id
- product_variant_id (kept for traceability; not used to re-derive
  price/name)
- product_name (snapshot)
- variant_name (snapshot)
- unit_price_cents (snapshot)
- quantity
- created_at
- updated_at

### Rules

- Snapshotted fields are never recomputed from the live `ProductVariant`
  after the order is placed, even if the product is later renamed,
  repriced, or deleted.

---

## ShippingAddresses

### Purpose

The delivery address for one Order.

### Attributes

- id
- order_id
- recipient_name
- line1
- line2
- city
- state
- postal_code
- country
- created_at
- updated_at

### Rules

- Belongs to exactly one order (addresses are captured per order, not
  reused from a stored address book in this version — a fan re-enters
  the address each purchase).
- `country` holds an ISO-3166-1 alpha-2 code, not a country name. This is
  what lets a destination be matched against a band's ShippingZones by
  equality; free text ("Brasil", "brazil", "BR") could not be matched
  reliably. Addresses written before the field became a select may still
  hold a name, so anything reading the column must tolerate that.
- `shipping_cents` on Order stays a plain snapshot rather than a reference
  to the zone that produced it, so a band re-pricing a destination never
  rewrites what a past order charged — and a carrier-rate API could replace
  the calculation later without migrating order data.

---

## ShippingZones

### Purpose

One destination a band ships to, and the flat rate it charges to send a
product there. Bands define their own (see `docs/product.md` Store →
Shipping).

### Attributes

- id
- band_id
- name (the band's own label, e.g. "Rest of world"; never shown to fans)
- shipping_cents
- position
- created_at
- updated_at

### Rules

- `name` is unique per band, case-insensitively.
- `shipping_cents >= 0` (DB check constraint). Zero is free shipping.
- Charged once per distinct product in an order, not per unit — two copies
  of one record ship together.
- **A country covered by no zone cannot be checked out.** A band's zone
  list is a sales territory as much as a price list; there is no
  platform-wide fallback rate.
- A band with no zones at all is the one exception: its products charge
  `products.shipping_cents` anywhere. Zones arrived after bands were
  already selling, and treating "not configured" as "ships nowhere" would
  have closed those stores.

---

## ShippingZoneCountries

### Purpose

One country inside a band's ShippingZone.

### Attributes

- id
- shipping_zone_id
- band_id (denormalised from the zone — see Rules)
- country_code (ISO-3166-1 alpha-2)
- created_at
- updated_at

### Rules

- `country_code` matches `^[A-Z]{2}$` (DB check constraint), the same
  format as `bands.country_code`.
- Unique on `(band_id, country_code)` (DB unique index). `band_id` is
  denormalised from the zone precisely so the database can enforce this:
  without it, two zones of one band could each claim BR and the rate for
  Brazil would depend on join order.

---

## ProductShippingRates

### Purpose

A product's own rate for one of its band's ShippingZones, overriding the
zone's figure for an item that is unusually heavy or light.

### Attributes

- id
- product_id
- shipping_zone_id
- shipping_cents
- created_at
- updated_at

### Rules

- `shipping_cents >= 0` (DB check constraint).
- Unique on `(product_id, shipping_zone_id)` (DB unique index).
- The zone must belong to the product's band — otherwise one band's rates
  could decide another band's shipping.
- **A missing row means "charge the zone's rate", which is not the same as
  a row holding 0** (deliberate free shipping for that item). Clearing the
  field in the product form deletes the row rather than storing a zero.

---

## Relationships

User
  ├── has_many BandMemberships
  ├── has_many Carts
  └── has_many Orders

Band
  ├── has_many BandMemberships
  ├── has_many Albums
  ├── has_many Products
  ├── has_many Carts
  ├── has_many Orders
  └── has_many ShippingZones
        └── has_many ShippingZoneCountries

Product
  └── has_many ProductShippingRates (one per ShippingZone, optional)

Album
  └── (links out to Spotify; no Tracks association since 2026-09-16)

Product
  └── has_many ProductVariants

ProductVariant
  └── has_many CartItems, OrderItems (via product_variant_id)

Cart
  ├── belongs_to User
  ├── belongs_to Band
  └── has_many CartItems

Order
  ├── belongs_to User
  ├── belongs_to Band
  ├── has_many OrderItems
  └── has_one ShippingAddress
