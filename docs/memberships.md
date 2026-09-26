# SceneCore Memberships

## 1. Purpose

This document defines the paid membership system of SceneCore.

Memberships represent the financial and relational connection between a fan and a specific band.

Membership determines:

- the fan's access level;
- exclusive content availability;
- membership benefits;
- participation privileges;
- discounts and early access;
- Core Member benefits.

Membership does **not** determine administrative authority.

Administrative authority is defined separately by `BandMembership` and platform administration rules.

---

# 2. Core Principle

SceneCore has two fundamentally different concepts:

### Fan Membership

A paid relationship between:

```text
User
  ↓
Band
  ↓
Membership
  ↓
Plan
```

It answers:

> "What level of support does this fan have with this band?"

### Administrative Membership

A relationship between a user and a band through `BandMembership`.

It answers:

> "What can this user administer within this band?"

These concepts must never be conflated.

A Core Member is not a Band Administrator.

A Band Administrator does not automatically become a Core Member.

A user can be:

- Fan of Band A;
- Supporter of Band B;
- Core Member of Band C;
- Band Administrator of Band D;

using the same SceneCore account.

---

# 3. Membership Plans

SceneCore defines three paid membership levels.

## 3.1 Fan

**Price:** US$ 3/month

### Promise

> Get closer to the band.

### Benefits

- Exclusive band feed through the band's posts section, with each post unlocked according to membership level
- News before the general public
- Behind-the-scenes photos
- Behind-the-scenes short videos — In development
- Selected demos
- Alternative versions of songs
- Poll participation
- Fan badge
- Subscriber community access

The Fan membership represents the first paid level of proximity to a band.

---

# 3.2 Supporter

**Price:** US$ 5/month

### Promise

> Support the music and follow its creation.

### Includes

Everything included in Fan, plus:

- Early access to releases
- Complete demos — In development
- Rehearsal recordings
- Composition journal
- Production journal
- Exclusive videos — In development
- Exclusive streams — In development
- Digital supporter credits
- Merchandise discounts
- Ticket discounts
- Early access to merchandise sales

Supporter represents a deeper financial and creative relationship with the band.

---

# 3.3 Core Member

**Price:** US$ 8/month

### Promise

> Become part of the band's core group.

### Includes

Everything included in Supporter, plus:

- Private periodic livestreams
- Private Q&A sessions
- Rare archives
- Old recordings
- Unreleased versions
- Priority access to tickets
- Priority access to limited products
- Higher discounts
- Permanent supporter page
- Selected liner/release credits
- Signed-item giveaways
- Direct messages to the band
- Participation in decisions selected by the band
- Special virtual meetings
- Special in-person meetings when offered by the band

Core Member represents the highest defined level of fan participation.

---

# 4. Membership Hierarchy

Memberships are cumulative.

```text
Fan
  ↓
Supporter
  ↓
Core Member
```

Therefore:

```text
Core Member >= Supporter >= Fan
```

A Core Member receives the benefits of Supporter and Fan.

A Supporter receives the benefits of Fan.

A Fan does not receive Supporter or Core Member benefits.

The system must not duplicate inherited benefits in the authorization layer.

---

# 5. Membership Is Band-Specific

A membership always belongs to a specific band.

It is invalid to model membership as:

```text
User.membership_plan
```

Instead:

```text
User
  |
  +-- Membership → Band A → Fan
  |
  +-- Membership → Band B → Supporter
  |
  +-- Membership → Band C → Core Member
```

The same user may have different membership levels for different bands.

---

# 6. Membership Lifecycle

A membership has a lifecycle independent from the membership plan.

Conceptually:

```text
pending
active
paused
cancelled
expired
```

The exact states must follow the approved subscription/payment architecture.

The membership level answers:

> What benefits does this plan provide?

The subscription state answers:

> Is the user currently entitled to those benefits?

Payment processing must not be implemented inside the Membership domain.

Payment provider behavior belongs to:

```text
docs/payments.md
```

Subscription lifecycle belongs to the Subscriptions phase of the roadmap.

---

# 7. Membership and Subscription

Membership and Subscription are related but should not be treated as the same concept.

### Membership

Represents the user's entitlement to a band's membership level.

### Subscription

Represents the recurring commercial relationship that maintains that entitlement.

Conceptually:

```text
User
  |
  +-- Subscription
  |      |
  |      +-- Band
  |      +-- Plan
  |      +-- payment state
  |
  +-- Membership entitlement
         |
         +-- Band
         +-- Membership level
```

The exact database relationship must follow the implementation approved during the Subscriptions phase.

---

# 8. Access Control

Membership benefits must be authorized server-side.

The application must never rely solely on:

- hidden UI elements;
- frontend conditionals;
- disabled buttons;
- URL obscurity;
- client-side membership checks.

For example:

```text
Fan
  → can access Fan content

Supporter
  → can access Fan + Supporter content

Core Member
  → can access Fan + Supporter + Core content
```

Unauthorized access must be rejected at the application layer.

Protected files must receive the same authorization treatment as protected pages.

---

# 9. Content Access Levels

Membership levels may be used as content visibility requirements.

Conceptually:

```text
Public
Fan
Supporter
Core
```

The system must determine the minimum required membership level.

Example:

```text
Post A → Public
Post B → Fan
Post C → Supporter
Post D → Core
```

A Core Member can access all four.

A Supporter can access A, B and C.

A Fan can access A and B.

A non-member can access only A.

The existing `Subscribers` visibility implementation must be reconciled with this model during the relevant roadmap phase rather than renamed blindly. The current roadmap explicitly states that subscriber visibility already exists but real subscriber access depends on the Subscriptions phase.

---

# 10. Benefits Must Be Domain Rules

Membership benefits must not be scattered through controllers as hardcoded checks.

Avoid:

```ruby
if current_user.membership == "supporter"
```

Prefer a domain-level authorization or benefit mechanism capable of answering:

```ruby
membership.can_access?(:early_release)
membership.can_access?(:composition_journal)
membership.can_access?(:core_session)
```

The implementation must remain as simple as possible.

Do not introduce a generic permission framework unless duplication or complexity actually requires it.

---

# 11. Discounts

Membership discounts are benefits of the membership plan.

They must not be hardcoded independently in:

- products;
- cart;
- checkout;
- tickets;
- orders.

The commercial calculation must use the user's active membership with the relevant band.

Orders must preserve the applicable commercial values at purchase time.

---

# 12. Early Access

Early access is a membership benefit.

Examples:

- early release access;
- early merchandise access;
- early ticket access.

Early access must be represented as a business rule rather than as a UI-only restriction.

The user must not be able to bypass early-access restrictions by directly accessing a URL.

---

# 13. Core Member Participation

Core Member participation may include:

- private sessions;
- Q&A;
- selected band decisions;
- special meetings;
- direct communication with the band.

These capabilities do not grant administrative permissions.

A Core Member must never be able to:

- edit band information;
- publish band content;
- manage albums;
- manage other members;
- manage subscriptions;
- access band financial data;
- administer another user's permissions.

Those capabilities belong to `BandMembership` administrative roles.

---

# 14. Membership and Community

Membership can grant access to band-specific community spaces.

The community rules are defined in:

```text
docs/community.md
```

Membership answers:

> Who can enter?

Community answers:

> What can members do once they are there?

---

# 15. Band Administration

Band administrators can manage the band's membership-related operations according to their administrative permissions.

They may eventually:

- view members;
- see membership levels;
- manage membership-related content;
- create exclusive experiences;
- manage community spaces;
- configure benefits approved by the product.

They must not gain access to another band's membership data.

Band-scoped authorization is mandatory.

The existing roadmap explicitly requires that an administrator of Band A cannot modify or access private information belonging to Band B.

---

# 16. Platform Administration

The SceneCore Administrator operates at the platform level.

Platform administration is separate from fan membership and band administration.

The platform administrator may have access to operational membership and subscription information when required for:

- moderation;
- support;
- fraud investigation;
- payment operations;
- compliance;
- auditing.

Access must follow least privilege.

---

# 17. Database Principles

The membership model must preserve:

- User → Band relationship;
- Plan;
- membership status;
- subscription relationship;
- timestamps;
- relevant external identifiers when required by the payment/subscription architecture.

Do not add speculative attributes.

Do not store calculated permissions redundantly if they can be derived safely from the active plan.

---

# 18. Testing

Membership tests must cover at minimum:

### Fan

- Fan can access Fan content.
- Fan cannot access Supporter content.
- Fan cannot access Core content.

### Supporter

- Supporter can access Fan content.
- Supporter can access Supporter content.
- Supporter cannot access Core content.

### Core

- Core can access Fan content.
- Core can access Supporter content.
- Core can access Core content.

### Different bands

- User can have different plans for different bands.
- Membership for Band A cannot grant access to Band B content.

### Administrative separation

- Core Member cannot administer a band unless separately authorized.
- Band Administrator does not automatically receive paid membership benefits.

### Lifecycle

- Inactive subscription does not continue granting benefits when the approved business rule says access must cease.
- Cancellation follows the approved subscription lifecycle.

---

# 19. Out of Scope

Unless explicitly approved, this document does not introduce:

- fan-to-fan social networking;
- cross-band membership;
- global membership plans;
- arbitrary custom membership tiers;
- cryptocurrency payments;
- referral systems;
- affiliate systems;
- speculative loyalty points;
- a generic permission framework;
- community features unrelated to the band/fan relationship.

---

# 20. Governing Principle

The central rule is:

> **Membership determines access and benefits. Role determines administrative authority.**

This distinction must remain true throughout the SceneCore implementation.
