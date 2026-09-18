# SceneCore Roadmap

## 1. Foundation

### 1.1 Project Analysis

Before implementing new features:

- Inspect the current Rails application.
- Identify the Rails and Ruby versions.
- Inspect the current database structure.
- Identify existing authentication.
- Identify existing user and band models.
- Identify existing payment infrastructure.
- Identify existing content/community infrastructure.

Do not implement code during the analysis phase.

---

# 2. Membership System

Implement the membership foundation before building advanced Band Admin features.

### Requirements

The system must support:

- Fan
- Supporter
- Core Member

Memberships must belong to the relationship between a user and a band.

A user may have different memberships for different bands.

### Detailed specification

Read:

`docs/band-admin.md`

The implementation must follow the membership, benefit, authorization and access-control rules defined there.

### Implementation order

1. Inspect existing User and Band models.
2. Determine whether Membership already exists.
3. Determine whether a subscription/payment model already exists.
4. Design the minimum required data model.
5. Implement migrations.
6. Implement models and relationships.
7. Implement membership status.
8. Implement benefit hierarchy.
9. Implement authorization.
10. Add tests.
11. Verify existing functionality.

---

# 3. Band Admin

Implement the Band Admin as a single administrative interface for each band.

### Requirements

Band Admin must be able to manage:

- Band profile
- Members
- Content
- Exclusive content
- Community
- Polls
- Releases
- Credits
- Memberships
- Benefits
- Engagement features

Do not create separate administrative dashboards for Fan, Supporter and Core Member.

### Detailed specification

Read:

`docs/band-admin.md`

### Implementation order

1. Verify existing authorization.
2. Verify band ownership/association.
3. Implement Band Admin authorization.
4. Implement dashboard.
5. Implement member management.
6. Implement content management.
7. Implement membership management.
8. Add tests.

---

# 4. Exclusive Content

Implement membership-based content access.

### Access hierarchy

```text
Public
  ↓
Fan
  ↓
Supporter
  ↓
Core Member
```

A higher membership automatically inherits access from lower levels.

Examples:

```text
Fan content
→ Fan
→ Supporter
→ Core Member

Supporter content
→ Supporter
→ Core Member

Core content
→ Core Member
```

### Detailed specification

Read:

`docs/band-admin.md`

### Requirements

Implement access control through centralized authorization.

Avoid scattering membership checks throughout controllers and views.

Add tests for:

- Public access
- Fan access
- Supporter access
- Core Member access
- Unauthorized access

---

# 5. Community

Implement:

- Exclusive feed
- Comments
- Polls
- Moderation

### Polls

Core Members may participate in decisions specifically selected by the band.

The band controls:

- question
- options
- eligible membership
- voting period
- result visibility

Core membership must not grant administrative authority.

### Detailed specification

Read:

`docs/band-admin.md`

---

# 6. Supporter Features

Implement:

- Early releases
- Complete demos
- Rehearsal recordings
- Composition journal
- Exclusive videos/lives
- Digital credits
- Merch discounts
- Early sales

### Detailed specification

Read:

`docs/band-admin.md`

Implement only features required by the current MVP.

---

# 7. Core Member Features

Implement:

- Private lives
- Q&A
- Rare archives
- Priority access
- Permanent supporter credits
- Selected release credits
- Signed-item giveaways
- Direct messages
- Community votes
- Special meetings

### Important

Do not implement a complex chat or event platform unless the current architecture and roadmap explicitly require it.

### Detailed specification

Read:

`docs/band-admin.md`

---

# 8. Commerce (membership benefits)

Implement membership-related commerce capabilities:

- Merch discounts
- Ticket benefits
- Early access
- Priority access

Reuse the existing payment/commerce infrastructure whenever possible.

Do not create a second payment system.

Note: this section is about benefits tied to a Fan/Supporter/Core Member
level (discounts, early access), not a general-purpose store any fan can
buy from. That is a separate, larger piece of work — see §8.1 Store below.

### Current implementation (2026-09-18)

- `MerchDiscount` is applied server-side to Store cart and checkout prices.
  The discounted unit price is snapshotted on each `OrderItem`, so later
  membership or discount changes do not alter an existing order.
- Discount eligibility uses the active membership for the product's band and
  follows the membership hierarchy. A Core Member inherits an available
  Supporter discount, while the highest configured eligible percentage wins.
- Product early/priority access is enforced server-side in the storefront,
  cart, checkout, and protected product attachments.
- Ticket benefits remain deferred until the ticketing integration described
  in `docs/band-admin.md` §20 exists.

### Detailed specification

Read:

`docs/band-admin.md`

---

# 8.1 Store (general product sales — approved 2026-09-17)

Implement product sales open to any fan (not membership-gated), per
`docs/product.md` §4.1 Store, `docs/database.md` (Products,
ProductVariants, Carts, CartItems, Orders, OrderItems,
ShippingAddresses), `docs/payments.md`, and ADR-007
(`docs/decisions.md`).

### Requirements

- Product with one or more variants (SKU); price and stock live on the
  variant.
- At most one active cart per user, scoped to one band at a time
  (ADR-003, clarified 2026-09-17).
- Checkout via Stripe Connect: each band needs an onboarded connected
  Stripe account before its Store can accept checkout; SceneCore's 10%
  commission is applied as `application_fee_amount` in the same
  transaction (ADR-007) — this is separate infrastructure from the plain
  Stripe Checkout Sessions Subscriptions (§7) already uses.
- Shipping address captured per order. Shipping cost is band-defined
  destinations, decided 2026-09-17 (`docs/product.md` Store → Shipping):
  a country no destination covers cannot be checked out at all. Weight-
  based rates and carrier-rate APIs were considered and rejected there —
  do not reintroduce either without confirming first.
- Order snapshots product name, variant name, and price at purchase time
  independent of later edits.
- Inventory (per variant) never goes negative under concurrent purchases.

### Implementation order

1. Inspect existing Stripe integration (`StripeClient`,
   `docs/architecture.md` §5) and Subscription flow as the pattern to
   extend, not replace.
2. Design and confirm the Stripe Connect band-onboarding flow (where in
   Band Admin a band starts/completes onboarding, and how an
   incomplete/restricted account blocks Store checkout).
3. Implement migrations/models: `Product`, `ProductVariant`, `Cart`,
   `CartItem`, `Order`, `OrderItem`, `ShippingAddress`.
4. Implement Band Admin product/variant management.
5. Implement the public Store (browse, add to cart, checkout).
6. Implement Stripe Connect checkout session creation with
   `application_fee_amount`.
7. Implement Store-specific webhook handling, distinguishing connected-
   account events from the platform-account events Subscriptions already
   handles (ADR-007).
8. Add tests: model, policy, request/system, concurrency (stock
   decrement), webhook idempotency and authenticity.
9. Update documentation if the implementation reveals a gap against
   `docs/database.md`/`docs/payments.md`.

Discogs Marketplace integration (`docs/product.md` §4.2) depends on this
section existing first, plus its own separate scoping pass — do not fold
Discogs-specific work into this implementation.

---

# 9. SceneCore Administrator

Implement a platform-level administrator separate from Band Admin.

### SceneCore Administrator can manage:

- Users
- Bands
- Memberships
- Payments
- Reports
- Moderation
- Platform analytics
- Platform settings
- Audit information

### Critical rule

```text
Band Admin
→ manages one band

SceneCore Administrator
→ manages the SceneCore platform
```

A Band Admin must never be able to administer another band's data.

### Detailed specification

Read:

`docs/band-admin.md`

---

# 10. Authorization

Maintain a strict distinction between:

### Membership

```text
Fan
Supporter
Core Member
```

and:

### Administrative roles

```text
User
Band Admin
SceneCore Administrator
```

Membership determines:

> What content and benefits the user can access.

Role determines:

> What administrative actions the user can perform.

### Detailed specification

Read:

`docs/band-admin.md`

---

# 11. Testing

Every membership rule must have automated tests.

At minimum test:

- Membership creation
- Membership status
- Membership hierarchy
- Content access
- Band Admin authorization
- SceneCore Administrator authorization
- Multi-band memberships
- Cross-band access prevention
- Subscription state changes
- Direct message authorization
- Poll authorization

Use the project's existing test framework.

Do not introduce another testing framework.

---

# 12. Implementation Rule

For every roadmap item:

1. Read the relevant documentation in `docs/`.
2. Inspect the existing implementation.
3. Identify what already exists.
4. Determine the smallest required change.
5. Explain the proposed implementation.
6. Implement one logical step.
7. Run tests.
8. Fix regressions.
9. Update documentation if necessary.
10. Continue to the next step.

Do not implement multiple unrelated roadmap sections at once.

---

# 13. Scope Control

The roadmap is not permission to invent features.

If a requirement is ambiguous:

1. Identify the ambiguity.
2. Explain the possible interpretations.
3. Ask for clarification when the decision materially affects architecture or product behavior.

Do not silently expand the MVP.
