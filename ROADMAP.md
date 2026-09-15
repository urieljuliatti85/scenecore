# ROADMAP

## 1. Purpose

This document defines:

* what will be implemented;
* in what order it will be implemented;
* the dependencies between phases;
* the expected deliverables;
* the acceptance criteria;
* what must be validated before moving forward.

This document is the implementation roadmap for the MVP.

`CLAUDE.md` defines how Claude must work.

`docs/product.md` defines what the product is.

`docs/architecture.md` defines how the system should be structured.

`docs/database.md` defines the data model.

`docs/permissions.md` defines authorization rules.

`docs/payments.md` defines financial and payment behavior.

This document defines the implementation sequence.

---

# 2. Roadmap Rules

## 2.1 Sequential implementation

Phases should be implemented in order unless a dependency requires a different sequence.

Claude must not skip a phase simply because a later feature appears easier to implement.

---

## 2.2 No implementation without a defined scope

Before implementing a roadmap item, there must be:

* a clearly defined objective;
* acceptance criteria;
* known dependencies;
* relevant product rules;
* relevant authorization rules;
* known database implications.

If these are missing, Claude must stop and ask for clarification.

---

## 2.3 One vertical slice at a time

Large phases must be divided into small, independently testable slices.

Example:

Do not implement:

> "Build the entire music system."

Instead implement:

1. Create track.
2. Edit track.
3. Save track as draft.
4. Publish track.
5. Display published track.
6. Protect unpublished track.
7. Add audio playback.

Each slice should have its own tests and acceptance criteria.

---

## 2.4 Definition of Done

A roadmap item is considered complete only when:

* implementation is finished;
* acceptance criteria are satisfied;
* automated tests pass;
* lint passes;
* authorization has been tested;
* relevant edge cases have been considered;
* no unrelated functionality was modified;
* the implementation has been manually reviewed;
* the feature has been validated in the appropriate environment.

A checkbox must not be marked complete merely because code exists.

---

## 2.5 Scope control

The following are prohibited unless explicitly approved:

* new product features;
* speculative abstractions;
* unnecessary dependencies;
* unrelated refactors;
* premature optimization;
* architecture changes outside the current phase;
* additional integrations;
* changes to previously approved business rules.

If Claude identifies a potentially useful feature, it should be recorded as a proposal and not implemented.

---

# 3. Phase 0 — Product Definition

## Objective

Define exactly what the MVP is before implementation begins.

## Deliverables

* `docs/product.md`
* initial `ROADMAP.md`
* documented user roles;
* documented user journeys;
* MVP scope;
* explicit out-of-scope features;
* acceptance criteria;
* open product questions.

## Tasks

### 0.1 Define product proposition

* [x] Define the problem.
* [x] Define the target audience.
* [x] Define the product solution.
* [x] Define the core value proposition.
* [x] Define SceneCore as a music-first digital home for the ongoing band–fan
      relationship.
* [x] Document complementary positioning relative to Spotify, Bandcamp, and
      Patreon.
* [x] Define the primary MVP metric that demonstrates a durable band–fan
      relationship (retained followers; see `docs/product.md` and
      ADR-006 in `docs/decisions.md`).

### 0.2 Define user types

* [x] Visitor
* [x] Fan
* [x] Band
* [x] Band administrator
* [x] Platform administrator

### 0.3 Define core journeys

All journeys are documented in `docs/product.md` §3, including the intended
flow for phases not yet built (Purchase a product, Subscribe, Purchase an
event ticket, Validate a ticket — each noted as not-yet-implemented there).

* [x] Discover a band.
* [x] View a band's public page.
* [x] Listen to music.
* [x] Create an account.
* [x] Follow a band.
* [x] Access exclusive content.
* [x] Purchase a product.
* [x] Subscribe.
* [x] Purchase an event ticket.
* [x] Validate a ticket.

### 0.4 Define MVP scope

Documented in `docs/product.md` §4 (Mandatory/Optional/Excluded), each
mandatory domain mapped to its ROADMAP.md phase.

* [x] List mandatory functionality.
* [x] List optional future functionality.
* [x] List explicitly excluded functionality.

### 0.5 Define product acceptance criteria

Documented in `docs/product.md` §5, one subsection per §4.1 mandatory
domain; unresolved requirements listed at the end of that section and
folded into §7 Open Questions.

* [x] Define acceptance criteria for every MVP domain.
* [x] Identify unresolved requirements.

## Exit criteria

Phase 0 is complete only when:

* the MVP scope is approved;
* out-of-scope functionality is documented;
* user roles are defined;
* core journeys are documented;
* major ambiguities have been resolved.

---

# 4. Phase 1 — Technical Foundation

## Objective

Create a stable Rails foundation before implementing business features.

## Deliverables

* Rails application;
* PostgreSQL;
* frontend foundation;
* testing framework;
* linting;
* CI;
* development environment;
* staging environment.

## Tasks

### 1.1 Application setup

* [x] Verify Ruby version.
* [x] Verify Rails version.
* [x] Configure PostgreSQL.
* [x] Configure environment variables.
* [x] Configure development environment.
* [ ] Configure production environment. Partially done: a `production`
      Railway environment exists and is live (`web` + `postgres`
      services, `web` tracking `main`) — see `docs/deployment.md`. Not
      done: no staging environment exists yet (despite the deploy flow
      describing one), and Active Storage/Postgres volumes are unresolved
      (see 1.3).

### 1.2 Frontend

* [x] Configure Hotwire.
* [x] Configure Stimulus.
* [x] Configure Tailwind CSS.
* [x] Establish basic layout.
* [x] Establish responsive foundation. Public/marketing pages already used
      responsive breakpoints; the gap was the header nav, which hid Bands/
      Your bands/Admin/search below the `sm` breakpoint with no
      replacement. Added a Stimulus-driven mobile menu (hamburger toggle)
      exposing the same links and search at phone width.

### 1.3 Storage

* [x] Configure Active Storage.
* [x] Define development storage.
* [ ] Define staging storage. Blocked on a staging environment existing at
      all (see 1.1).
* [x] Define production storage (2026-09-15). A Railway Volume
      (`scenecore-active-storage`, 500MB) is mounted on the `web` service
      at `/rails/storage`, with `ACTIVE_STORAGE_PATH` pointing
      `config/storage.yml`'s new `production` entry at it and
      `production.rb` using `service: :production`. Before this,
      production used `:local` — rooted at the container filesystem, so
      every uploaded band photo, album cover and post image was discarded
      on the next deploy. See `docs/deployment.md` for the reasoning and
      the trigger for moving to object storage.

### 1.4 Testing

* [x] Configure test framework.
* [x] Configure system tests.
* [x] Configure request tests.
* [x] Configure test database.

### 1.5 Quality

* [x] Configure RuboCop.
* [x] Configure security checks.
* [x] Configure CI.
* [x] Verify CI runs tests.
* [x] Verify CI runs lint.

### 1.6 Error handling

* [x] Establish application error handling.
* [x] Establish production logging.
* [x] Establish basic health check.

## Exit criteria

* [x] Application boots locally.
* [x] PostgreSQL connection works.
* [x] Tests pass.
* [x] Lint passes.
* [x] CI passes.
* [ ] Staging environment is operational.

---

# 5. Phase 2 — Identity and Authentication

## Objective

Establish users and authentication before implementing protected resources.

## Tasks

### 2.1 User

* [x] User model.
* [x] User database structure.
* [x] User validations.
* [x] User tests.

### 2.2 Authentication

* [x] Registration.
* [x] Login.
* [x] Logout.
* [x] Session management.
* [x] Authentication failure behavior.

### 2.3 Profile

* [x] User profile.
* [x] Edit profile.
* [x] Profile validation. `User` already validates name presence
      (whitespace-only names are rejected by Rails' `blank?`) plus
      Devise's `:validatable` (email format/uniqueness/presence, password
      rules). No length/format constraints exist on any model's `name`
      field in this codebase (Band, Category included) and no DB check
      constraints exist yet at all, so adding one to User alone would be
      an arbitrary, inconsistent new pattern rather than closing a real
      gap — not done, by explicit decision.

### 2.4 Authorization foundation

* [x] Define authorization mechanism.
* [x] Define authenticated access.
* [x] Test unauthorized access.
* [x] Test unauthenticated access.

## Exit criteria

* [x] User can register.
* [x] User can authenticate.
* [x] User can log out.
* [x] Protected resources require authentication.
* [x] Authentication tests pass.

---

# 6. Phase 3 — Bands and Memberships

## Objective

Create the multi-band foundation.

## Tasks

### 3.1 Band

* [x] Band model.
* [x] Band creation.
* [x] Band editing.
* [x] Band slug.
* [x] Band status.
* [x] Band validations.

### 3.2 Membership

* [x] Band membership model.
* [x] User-to-band relationship.
* [x] Membership roles.
* [x] Multiple members per band.

### 3.3 Band administrators

* [x] Administrator role.
* [x] Add administrator.
* [x] Remove administrator.
* [x] Authorization rules.

### 3.4 Band approval

* [x] Define band approval status.
* [x] Pending state.
* [x] Approved state.
* [x] Rejected state.
* [x] Platform administrator approval.

### 3.5 Isolation

Test that:

* [x] Band A administrator can manage Band A.
* [x] Band A administrator cannot manage Band B.
* [x] Band A cannot access Band B private resources.
* [x] Band IDs cannot be manipulated to bypass authorization.

## Exit criteria

The multi-band authorization model is operational and tested.

---

# 7. Phase 4 — Public Band Pages

## Objective

Allow visitors and fans to discover bands.

## Tasks

### 4.1 Public band page

Implemented as `GET /:slug` via `PublicBandsController`, deliberately
separate from the band management area (`BandsController`/`BandPolicy`,
which stays members/platform-admin only). Includes the band's published
albums and tracks — pulled forward from Phase 5, since Phase 5's exit
criteria (a visitor can play a published track) depends on it.

* [x] Band name.
* [x] Description.
* [x] Logo (`Band#photo`, now rendered on the public band page).
* [x] Cover (2026-09-14: no separate "cover" field exists anywhere in the
      product docs, and `Band#photo` was already used as a full-bleed hero
      image on the home page — reused that same treatment on the public
      band page instead of adding a new attachment, resolving Logo and
      Cover together).
* [x] Links (social links rendered via `shared/social_links`).
* [x] Public status (approved bands are visible; pending/rejected are not).

### 4.2 Custom URL

* [x] Generate slug (`Band#generate_slug`, on create).
* [x] Validate uniqueness (DB unique index + model validation).
* [x] Resolve public band URL (`GET /:slug`, constrained and ordered last
      in `routes.rb` so it doesn't shadow other routes).
* [x] Handle invalid slugs (2026-09-15: `PublicBandsController#show`/
      `#album` now render `public_bands/not_found`, a branded 404 view
      with links back to Discover/home, instead of a bare `head
      :not_found`; status stays 404).

### 4.3 Responsive interface

* [x] Desktop layout (already responsive via Tailwind `sm:`/`lg:`
      breakpoints; no dedicated desktop-only layout was required or
      built).
* [x] Mobile layout (public pages already responsive; header nav fixed to
      expose all links below the `sm` breakpoint via a mobile menu).
* [x] Accessible navigation (mobile menu button has `aria-label`,
      `aria-expanded`, `aria-controls`).
* [ ] Loading states (not applicable: the public band page is fully
      server-rendered with no async/Turbo Frame requests today; would
      require an architecture change outside this slice's scope).
* [x] Empty states (2026-09-15: when a band has no published albums and
      no visible posts, `public_bands/show` now renders a dashed-border
      placeholder instead of silently omitting both sections).
* [x] Error states (covered by the 404 page above; no other error state
      exists on this page today).

## Exit criteria

A visitor can access an approved band's public page without authentication.

---

# 8. Phase 5 — Music

## Objective

Allow bands to manage and publish music.

## Tasks

### 5.1 Albums

An album groups a band's tracks into a release. A track always belongs to
an album — there is no ungrouped track.

* [x] Album model.
* [x] Album belongs to band.
* [x] Create album (imported from Spotify search; see `AlbumsController`).
* [x] Edit album (2026-09-14: `AlbumsController#edit`/`#update` added,
      scoped to the cover only — title/tracks stay Spotify-import-only).
* [x] Album cover (Active Storage, same validation as `Band#photo` via
      the shared `HasImage` concern; set from the album's edit page).
* [x] Album publication state.

### 5.2 Tracks

* [x] Track model.
* [x] Track belongs to album (and, through it, to a band).
* [x] Track title.
* [x] Track number (position within the album).
* [x] Draft state.
* [x] Published state.

### 5.3 Audio (via Spotify link, no file upload)

Decision: track audio is not hosted by SceneCore. A track stores a link to
its corresponding Spotify track, and playback happens through Spotify's
official embed. No Active Storage attachment, no file upload, no audio
file validation.

* [x] Track stores a Spotify track URL.
* [x] Validate the URL matches Spotify's track URL format.
* [x] Handle a track with no Spotify link yet (allowed while in draft).

### 5.4 Publishing

Decision: publishing happens at the album level, not per track. Publishing
an album publishes every track that already has a Spotify link; tracks
without a link stay draft until one is added. Unpublishing an album
reverts all of its tracks to draft. There is no standalone publish/unpublish
action on a track.

* [x] Save track as draft (default state; also the effective state for a
      track with no Spotify link, even if its album is published).
* [x] Publish album (cascades to tracks that have a Spotify link).
* [x] Unpublish album (cascades to all tracks).
* [x] Hide unpublished tracks from public users (see 4.1: `GET /:slug`
      only renders published albums/tracks).
* [x] A track cannot be published without a Spotify link.

### 5.5 Player (Spotify embed)

* [x] Display Spotify's official embed player for a published track's link
      (`Track#spotify_embed_url`, rendered on the public band page).
* [x] Display track information (title).
* [x] Handle missing/invalid Spotify link gracefully (no embed shown).

### 5.6 Security

Audited the existing implementation; no production code changes were
needed. Track has no standalone `show` route (only `edit`/`update`,
both authenticated and band-scoped), so a draft track is only ever
reachable through `GET /:slug`, which already filters to published
albums/tracks.

* [x] Verify unpublished tracks are not exposed to visitors (no Spotify
      link leaked, no route to reach the track).
* [x] Verify authorization server-side.

## Exit criteria

A band administrator can publish a track linked to Spotify and a visitor can play it through the embedded Spotify player.

---

# 9. Phase 6 — Followers

## Objective

Allow fans to follow bands.

## Tasks

* [x] Follow relationship (`Follow` model: `user_id`, `band_id`, unique
      composite index).
* [x] Follow a band (`POST /bands/:band_id/follow`, any authenticated
      user, band must be approved).
* [x] Unfollow a band (`DELETE /bands/:band_id/follow`).
* [x] Prevent duplicate follows (unique index + model validation;
      `create` is idempotent via `find_or_initialize_by`).
* [x] Display following state (Follow/Following button and follower
      count on the public band page).
* [x] Test authorization (`FollowPolicy`: anonymous cannot follow, a
      user cannot unfollow on another user's behalf, band must be
      approved to be followed).

Follower count (`Band#followers_count`) was added ahead of schedule,
alongside this slice. Notifications and a fan-facing feed were
requested but have no defined scope (channel, trigger, or UI aren't
specified anywhere) — recorded under Future Features instead of
implemented, per the roadmap's rule against speculative scope.

## Exit criteria

A user can follow and unfollow a band and the relationship is persisted correctly.

---

# 10. Phase 7 — Exclusive Content

Sliced (2026-09-14): implemented Posts with Public and Followers
visibility, which have everything they depend on already built. Subscriber
visibility exists in the `Post#visibility` enum and is fully wired into the
authorization logic (a subscriber post is never shown to anyone, follower
or not — see `PublicBandsController#visible_posts`), but there is no way
for anyone to become a Subscriber yet — that depends on Phase 10
(Subscriptions), which doesn't exist. Resume once Phase 9/10 land: add
`subscribers` to the allowed visibilities once there's a real subscription
to check against.

## Objective

Allow bands to publish content with different visibility levels.

## Visibility Levels

* Public
* Followers
* Subscribers (schema/enum ready; not reachable yet — see note above)

## Tasks

### 10.1 Posts

* [x] Post model.
* [x] Create post.
* [x] Edit post.
* [x] Delete post.
* [x] Draft state.
* [x] Published state.

### 10.2 Media

* [x] Images (2026-09-15: `Post` reuses the existing `HasImage` concern
      — same content-type/size validation as `Band#photo`/`Album#cover`
      — via `has_image :image`; rendered on the public band page when
      attached).
* [ ] Videos (no pattern exists yet for video storage/validation —
      out of scope for this slice).
* [ ] Downloads (same — undefined storage/access pattern, out of scope
      for this slice).
* [x] File validation (covered by `HasImage`: PNG/JPEG/WebP, up to 5MB).
* [x] Storage (Active Storage, same as existing image attachments).

### 10.3 Visibility

* [x] Public content.
* [x] Follower content.
* [ ] Subscriber content (blocked on Phase 10 — Subscriptions).

### 10.4 Authorization

Test:

* [x] Visitor cannot access follower content.
* [x] Non-follower cannot access follower content.
* [ ] Non-subscriber cannot access subscriber content (no subscribers
      exist yet to test against).
* [ ] Subscriber can access subscriber content (blocked on Phase 10).
* [x] Band administrators can manage their band's content.
* [x] Another band's administrator cannot modify content.

### 10.5 File protection

2026-09-15: audited while adding Post#image (see 10.2). Found and fixed a
real gap — Active Storage's default blob redirect route is publicly
accessible to anyone with the URL, forever, regardless of the owning
record's visibility (Rails' own controller source code warns about this
explicitly). A draft album's cover, a pending band's photo, and a
followers-only post's image were all reachable by direct URL with no
authorization check. Fixed by routing blob redirects through
`AuthenticatedBlobsController`, which checks `AttachmentVisibility`
(same public/approved/published/followers rules `PublicBandsController`
already applies, plus band-membership access for the management area)
before redirecting to the file.

* [x] Protected files are not exposed through predictable URLs (URLs were
      already signed; the gap was authorization, not guessability — see
      above).
* [x] Direct access is authorized (`AuthenticatedBlobsController`).
* [x] Authorization is enforced server-side (`AttachmentVisibility`,
      covered by `spec/requests/authenticated_blobs_spec.rb`).

## Exit criteria

Content visibility works correctly at both the application and file-storage levels.

---

# 11. Phase 8 — Store

**Skipped for now (2026-09-14):** by explicit decision, not attempted this
round. Note for whoever resumes it: the exit criteria ("a fan can purchase
an available product and the order/inventory state remains consistent")
has the same structural issue Phase 7 had with Subscriptions — Order
states (`paid`, `processing`, `completed`, per `docs/payments.md`) are
sourced from the payment provider, which doesn't exist until Phase 9. A
sliceable approach was scoped (Products/Variants/Inventory/Cart without
checkout) but not implemented. One open product question if this is
picked up: whether a cart requires authentication, or a visitor can start
one before creating an account (`docs/product.md` leaves this
unresolved).

## Objective

Allow bands to sell products.

## Tasks

### 11.1 Products

* [ ] Product model.
* [ ] Product title.
* [ ] Description.
* [ ] Price.
* [ ] Images.
* [ ] Publication status.
* [ ] Band ownership.

### 11.2 Variants

* [ ] Variant model when required.
* [ ] Variant attributes.
* [ ] Variant price when applicable.
* [ ] Variant inventory.

Do not create variants unless the product actually requires combinations.

### 11.3 Inventory

* [ ] Stock quantity.
* [ ] Stock validation.
* [ ] Inventory changes.
* [ ] Prevent negative inventory.
* [ ] Handle concurrent purchases.

### 11.4 Cart

* [ ] Cart.
* [ ] Cart items.
* [ ] Add product.
* [ ] Remove product.
* [ ] Update quantity.
* [ ] Calculate totals.

### 11.5 Single-band rule

For the MVP:

* [ ] A cart belongs to one band.
* [ ] Products from another band cannot be added to the current cart.
* [ ] Checkout cannot contain products from multiple bands.

### 11.6 Orders

* [ ] Order creation.
* [ ] Order items.
* [ ] Price snapshot.
* [ ] Product snapshot.
* [ ] Order status.

### 11.7 Concurrency

Test:

* [ ] Two simultaneous purchases cannot consume nonexistent inventory.
* [ ] Inventory remains consistent after failed payment.
* [ ] Cancelled orders release inventory when appropriate.

## Exit criteria

A fan can purchase an available product and the order/inventory state remains consistent.

---

# 12. Phase 9 — Payments

**Skipped for now (2026-09-14):** by explicit decision, not attempted
this round. Two unresolved dependencies: (1) no payment provider is
named anywhere — `docs/payments.md` only says "the approved payment
provider" without specifying which one (Stripe? Mercado Pago? Pagar.me?
Pix requires a Brazil-capable provider) — this is a product/business
decision, not one to make unilaterally; (2) Payments processes Orders
(Phase 8, also skipped) and Subscriptions (Phase 10, doesn't exist) —
there's nothing to process yet even once a provider is chosen. Resume
once a provider is named and at least one of Phase 8/10 exists.

## Objective

Integrate the approved payment provider.

## Important Rule

Payment implementation must follow `docs/payments.md`.

Do not invent payment behavior during implementation.

## Tasks

### 12.1 Provider integration

* [ ] Configure credentials.
* [ ] Configure test environment.
* [ ] Implement provider client.
* [ ] Handle provider errors.

### 12.2 One-time payments

* [ ] Create checkout.
* [ ] Redirect/checkout flow.
* [ ] Pending state.
* [ ] Paid state.
* [ ] Failed state.
* [ ] Cancelled state.

### 12.3 Pix

* [ ] Pix payment flow.
* [ ] Pending payment.
* [ ] Confirmation.
* [ ] Expiration.

### 12.4 Card

* [ ] Card checkout.
* [ ] Authorization.
* [ ] Payment confirmation.
* [ ] Failure handling.

### 12.5 Webhooks

* [ ] Validate authenticity.
* [ ] Persist external event identifier.
* [ ] Ensure idempotency.
* [ ] Handle duplicate events.
* [ ] Handle unexpected events.
* [ ] Handle provider retries.

### 12.6 Refunds

* [ ] Refund state.
* [ ] Provider refund request.
* [ ] Refund webhook.
* [ ] Order state update.

### 12.7 Financial records

* [ ] Persist payment state.
* [ ] Persist external payment ID.
* [ ] Persist relevant transaction information.
* [ ] Maintain auditability.

## Exit criteria

The complete payment lifecycle works in the provider's test environment.

---

# 13. Phase 10 — Subscriptions

## Objective

Allow fans to subscribe to band plans.

## Tasks

### 13.1 Plans

* [ ] Plan model.
* [ ] Plan name.
* [ ] Price.
* [ ] Billing interval.
* [ ] Band ownership.
* [ ] Active/inactive state.

### 13.2 Subscription

* [ ] Subscription model.
* [ ] User relationship.
* [ ] Band relationship.
* [ ] Plan relationship.
* [ ] External subscription ID.
* [ ] Subscription status.

### 13.3 Lifecycle

Support:

* [ ] Pending.
* [ ] Active.
* [ ] Past due.
* [ ] Cancelled.
* [ ] Expired.

### 13.4 Billing

* [ ] Initial payment.
* [ ] Recurring payment.
* [ ] Failed payment.
* [ ] Recovery.
* [ ] Cancellation.

### 13.5 Webhooks

* [ ] Validate webhook.
* [ ] Ensure idempotency.
* [ ] Process subscription events.
* [ ] Process payment events.

### 13.6 Content access

* [ ] Active subscriber gets subscriber content.
* [ ] Cancelled subscription loses access according to the approved business rule.
* [ ] Failed payment follows the approved grace-period rule.

## Exit criteria

Subscription state and content access remain synchronized with the payment provider.

---

# 14. Phase 11 — Events and Tickets

## Objective

Allow bands to create events and sell tickets.

## Tasks

### 11.1 Events

* [ ] Event model.
* [ ] Event title.
* [ ] Description.
* [ ] Date/time.
* [ ] Location.
* [ ] Publication state.

### 11.2 Ticket batches

* [ ] Ticket batch model.
* [ ] Price.
* [ ] Quantity.
* [ ] Start/end availability.
* [ ] Batch activation.

### 11.3 Ticket purchase

* [ ] Select ticket.
* [ ] Checkout.
* [ ] Payment.
* [ ] Ticket creation.

### 11.4 QR code

* [ ] Generate unique ticket identifier.
* [ ] Generate QR code.
* [ ] Associate QR code with ticket.
* [ ] Protect ticket data.

### 11.5 Check-in

* [ ] Scan/validate ticket.
* [ ] Mark ticket as used.
* [ ] Prevent duplicate check-in.
* [ ] Display invalid/used ticket state.

### 11.6 Cancellation

* [ ] Cancel ticket according to business rules.
* [ ] Handle refund when applicable.

## Exit criteria

A user can purchase a ticket and the ticket can be validated exactly according to the approved rules.

---

# 15. Phase 12 — Platform Administration

Sliced (2026-09-14): implemented 12.1 (Band moderation) and 12.4
(Administrative audit). 12.2 (Content moderation) is deferred — there is
no report/flag system defined anywhere in the product docs, so "review
reported content" has no defined scope yet (would need product input:
who can report, what triggers a review, what "remove content" means
across albums/tracks/posts). 12.3 (Orders and payments) is blocked on
Phase 8/9, both skipped this round.

## Objective

Provide platform-level controls.

## Tasks

### 12.1 Band moderation

* [x] Review pending bands (`bands#index` already scopes to all bands
      for a platform admin via `BandPolicy::Scope`; approve/reject/
      suspend/reactivate controls live on each band's page).
* [x] Approve band.
* [x] Reject band.
* [x] Suspend band when applicable (new `suspended` status; a
      suspended band's public page becomes inaccessible, same as
      pending/rejected).

### 12.2 Content moderation

Sliced (2026-09-14): "review reported content" stays blocked — no
reporting/flagging system is defined in the product docs. But a minimal,
explicitly-scoped moderation action was implemented: a platform admin
can unpublish any band's published album (and its tracks revert to
draft along with it), reversible, no new business rule invented — it
reuses the same publish/draft mechanics `AlbumsController#unpublish`
already has, just authorized differently (platform admin, not band
membership). Deleting content outright was considered and explicitly
not built — unpublish is reversible, destroy is not, and nothing asked
for permanent removal.

* [ ] Review reported content (blocked — no reporting/flagging system
      is defined in the product docs).
* [x] Remove content when authorized (unpublish, not delete — see
      `Admin::AlbumsController#unpublish`).
* [x] Record administrative action (`AdminActionLog`, action
      `moderate_unpublish_album`).

### 12.3 Orders and payments

* [ ] View orders (blocked on Phase 8).
* [ ] View payment status (blocked on Phase 9).
* [ ] Process approved refunds (blocked on Phase 9).
* [ ] View relevant payment events (blocked on Phase 9).

### 12.4 Administrative audit

* [x] Record important administrative actions (new `AdminActionLog`
      model, polymorphic `subject`; written on approve/reject/suspend/
      reactivate).
* [x] Record actor.
* [x] Record timestamp (`created_at`).
* [x] Record affected resource (`subject_type`/`subject_id`).

### 12.5 Admin panel (added 2026-09-14)

A dedicated `/admin` namespace, restricted to `platform_admin: true`
(404 for anyone else, same "don't leak existence" pattern used
elsewhere). Requested alongside this phase; not originally a roadmap
item, added here since it's squarely Platform Administration scope.

* [x] Bands — list all bands (with a status filter), linking into the
      existing per-band management page for approve/reject/suspend.
* [x] Users — list all users.
* [x] Privileges — grant/revoke a band's administrator role for any
      user, reusing `BandMembership`'s existing "a band can never be
      left without an administrator" rule (no new rule invented).
* [ ] Subscriptions — not built; blocked on Phase 9/10, both skipped.
* [x] Content moderation (albums) — added 2026-09-14: platform admin
      can unpublish any band's published album (see 12.2).

## Exit criteria

Platform administrators can perform approved administrative actions without gaining inappropriate access to unrelated user data.

---

# 16. Phase 13 — Security Audit

## Objective

Validate the system before production.

2026-09-15: first pass done (Authentication, Authorization, Files). Found
and fixed two real gaps (session cookies, Spotify ID injection); found and
documented one gap that needs infrastructure not yet in place (email
confirmation). Payments/Application sections not started — Payments is
blocked on Phase 9 (skipped), Application overlaps with Phase 15
(Production Readiness) and wasn't attempted this round.

## Authentication

* [x] Authentication boundaries reviewed (Devise `database_authenticatable,
      :registerable, :recoverable, :validatable`; standard config, no
      custom bypass logic found).
* [x] Session behavior reviewed. Found: `config/environments/production.rb`
      had `force_ssl`/`assume_ssl` commented out (the default `rails new`
      state) — Railway terminates TLS at its edge and forwards plain HTTP,
      so without these, session cookies were never marked `Secure` and
      there was no HTTP→HTTPS redirect or HSTS. Fixed: both enabled (health
      check path excluded from the redirect, per Rails' own guidance
      comment).
* [x] Password/security mechanisms reviewed. Found and **not** fixed this
      round: `User` doesn't use Devise's `:confirmable`, so
      `ProfilesController#update` lets a signed-in user change their email
      instantly with no proof they control the new address. Not fixed
      because `:confirmable` requires a working confirmation-email flow,
      and production has no SMTP configured yet (`action_mailer.smtp_settings`
      is commented out in `production.rb`) — the same gap password-reset
      already depends on. Needs that infrastructure decision first, not a
      silent code change.

## Authorization

* [x] Band isolation tested (existing specs: `spec/requests/albums_spec.rb`,
      `posts_spec.rb`, `band_memberships_spec.rb`, `tracks_spec.rb` all
      cover "member of another band" scenarios; controllers scope lookups
      through `@band.albums.find`/`@band.posts.find`/etc., not global
      `Model.find`, so cross-band IDOR isn't reachable).
* [x] Private content tested (draft albums/tracks/posts already covered
      by `spec/requests/public_bands_spec.rb`; see also Files below for
      the attachment-level gap found and fixed in #61).
* [x] Administrative permissions tested (`Admin::BaseController` 404s
      non-platform-admins before any admin action runs; reviewed every
      `Admin::*Controller` — all scope through the band/record from the
      URL, no global unscoped lookups).
* [x] Object-level authorization tested (reviewed every Pundit policy —
      `AlbumPolicy`, `PostPolicy`, `TrackPolicy`, `BandMembershipPolicy`,
      `FollowPolicy` — all check membership via `record.band`, not a
      global role).

## Files

Closed in #61 (2026-09-15) — see Phase 7.5 for the full writeup of the
Active Storage blob-authorization gap found and fixed.

* [x] Private files protected (`AuthenticatedBlobsController`).
* [x] Upload validation verified (`HasImage`: content-type/size, reused
      by `Band#photo`, `Album#cover`, `Post#image`).
* [x] File access authorization verified (`AttachmentVisibility`, see
      `spec/requests/authenticated_blobs_spec.rb`).

## Payments

* [ ] Webhook authenticity verified (blocked — Phase 9 skipped, no
      payment provider integration exists yet).
* [ ] Webhook idempotency verified (blocked — same).
* [ ] Sensitive payment information not logged (blocked — same).

## Application

Not attempted this round — overlaps with Phase 15 (Production Readiness),
which is also entirely unstarted.

* [ ] Secrets are not committed.
* [ ] Environment variables are used correctly.
* [ ] Security checks pass.
* [ ] Error pages do not expose sensitive information.

## Exit criteria

No critical security issue remains unresolved.

---

# 17. Phase 14 — Performance and Reliability

## Objective

Find obvious production problems before launch.

## Tasks

### Database

2026-09-15: Database section audited. Indexes and foreign keys were
already correct — no changes needed. Two real problems found and fixed:
the database had no CHECK constraints at all, and one N+1 in the band
management page.

* [x] Review indexes (every foreign key is indexed, and the composite
      indexes match the queries actually run: `albums(band_id, status)`,
      `tracks(album_id, status)`, `posts(band_id, status, visibility)`,
      plus unique indexes on `bands.slug`, `categories.slug`,
      `users.email`, `band_memberships(user_id, band_id)` and
      `follows(user_id, band_id)`. No changes needed).
* [x] Review foreign keys (all eight associations have one; no orphan
      columns found. No changes needed).
* [x] Review constraints. Found: the database had **zero** CHECK
      constraints, so every enum-backed column (`bands.status`,
      `band_memberships.role`, `albums.status`, `tracks.status`,
      `posts.status`, `posts.visibility`) was a free-form string
      enforced only by model validations — which `update_all` bypasses,
      and `AlbumsController`/`Admin::AlbumsController` use `update_all`
      on `status` in three places today. Added CHECK constraints for all
      six (see `AddEnumCheckConstraints`), covered by
      `spec/models/database_constraints_spec.rb`.
* [x] Identify N+1 queries. Found one: `bands/show.html.erb` eager-loaded
      `:tracks` and then called `album.tracks.order(:track_number)` inside
      the loop, which discards the preloaded association and issues a
      fresh query per album (measured: 4 track queries for 3 albums, vs 1
      after). Fixed by sorting the loaded association in memory; regression
      guard in `spec/requests/bands_spec.rb`. Checked the other views that
      walk associations (`admin/albums`, `admin/privileges`,
      `band_memberships`, `search`, `pages/home`, `public_bands`) — all
      already eager-load correctly.
* [ ] Review expensive queries. Not done — needs production data volume
      to be meaningful, and production currently has no real traffic.
      One known inefficiency recorded for when it does: `public_bands#index`
      loads every follower record via `includes(:followers)` purely to call
      `followers.size` for a count, and sorts in Ruby rather than SQL.
      Fine at current scale, wrong shape at large scale — revisit with a
      counter cache or a `COUNT` aggregate when there's data to measure.

### Background jobs

2026-09-15: audited, including against the live Railway production
environment. Found that production's job/cache/cable backends were all
configured but non-functional, and fixed that; there is still no
application-owned background work to configure retries or idempotency for.

* [x] Identify asynchronous workloads. There are none of the app's own —
      `app/jobs/` contains only the generated `ApplicationJob` with
      everything commented out. The only job enqueued today is Active
      Storage's `AnalyzeJob` (image metadata extraction, on upload).
* [x] Configure retries. Found and fixed a real problem first:
      `production.rb` set `queue_adapter = :solid_queue` and
      `cache_store = :solid_cache_store`, and `cable.yml` set
      `adapter: solid_cable` — but `config/database.yml` declares a single
      database with no `queue`/`cache`/`cable` connections, so
      `db/queue_schema.rb` and `db/cache_schema.rb` are never loaded and
      those tables do not exist. Every enqueue and cache write in
      production was hitting a missing table. Confirmed against the live
      Railway environment: only `web` and `postgres` services exist, no
      worker service, and `SOLID_QUEUE_IN_PUMA` (which `config/puma.rb`
      checks) is not set, so nothing would have drained the queue even if
      the tables existed. Switched to `:async`/`:memory_store`/`async`
      cable, which match what production actually is: one web replica with
      no durable background work. Retry configuration is deferred with the
      workloads themselves — there is nothing to retry yet.
* [x] Handle failed jobs (nothing to handle: no app-owned jobs, and the
      backend now actually runs rather than erroring on enqueue).
* [x] Verify job idempotency where necessary (not applicable yet — no
      app-owned jobs).

Trigger to revisit: the in-process adapters are per-process, so work is
lost on restart and not shared between replicas. Before adding a second
`web` replica or any job that must survive a restart, add the
`queue`/`cache` connections to `database.yml` so `db:prepare` creates the
tables, then move back to Solid Queue/Cache and run a worker (either
`SOLID_QUEUE_IN_PUMA=true` or a dedicated service). A guard spec
(`spec/models/production_backends_spec.rb`) fails if production is pointed
back at a Solid backend without that connection existing.

### Storage

2026-09-15: all three were resolved by work done elsewhere this round;
recorded here rather than re-audited.

* [x] Verify media storage. Production was writing uploads to the
      container filesystem (`:local`), so every band photo, album cover
      and post image was discarded on the next deploy. Now backed by a
      Railway Volume — see 1.3 and `docs/deployment.md`.
* [x] Verify upload limits (`HasImage` enforces PNG/JPEG/WebP and a 5MB
      ceiling for every image attachment: `Band#photo`, `Album#cover`,
      `Post#image`).
* [x] Verify private file access (Active Storage blob URLs were publicly
      readable regardless of the owning record's visibility; now checked
      by `AuthenticatedBlobsController` — see Phase 7.5).

### Reliability

2026-09-15: audited. App-level error handling was already sound; the
Spotify client had two real problems, both fixed.

* [x] Verify error handling (`ApplicationController` rescues
      `Pundit::NotAuthorizedError`; `PublicBandsController` renders a
      branded 404 for unknown slugs/albums; `AlbumsController` and
      `BandsController` handle `RecordInvalid`; the standard 400/404/422/500
      pages exist. No changes needed).
* [x] Verify external service failures. Spotify is the only external
      dependency, and two problems were found:
      (1) **No timeouts.** `Net::HTTP.start` was called without
      `open_timeout`/`read_timeout`, so it used Ruby's 60s-per-phase
      default. These calls happen inside a web request and production runs
      Puma with 3 threads on a single replica, so a slow (not down)
      Spotify could stall the entire app. Now bounded at 3s connect / 5s
      read.
      (2) **Network failures escaped as raw exceptions.** Callers rescue
      `SpotifyClient::Error` to show "Spotify is unavailable", but
      `Errno::ECONNREFUSED`, `Net::OpenTimeout`, `SocketError`,
      `OpenSSL::SSL::SSLError` and friends are not that class, so they
      bypassed the rescue and became 500s. Confirmed by reproduction
      before fixing. All connection-level failures and unparseable bodies
      are now wrapped as `SpotifyClient::Error`, so the intended
      degradation actually happens — covered by
      `spec/services/spotify_client_spec.rb` and an end-to-end case in
      `spec/requests/albums_spec.rb`.
* [ ] Verify payment provider downtime behavior (blocked — Phase 9
      skipped, no payment provider integration exists).

## Exit criteria

No known critical performance or reliability issue remains.

---

# 18. Phase 15 — Production Readiness

## Objective

Prepare the application for real users.

## Tasks

2026-09-15: audited against the live Railway environment. Several items
were already satisfied by work done this round but had never been recorded
here; they are ticked below with the evidence. The genuinely missing pieces
are database persistence/backup, error monitoring, email, and a custom
domain.

### Infrastructure

* [x] Production application (Railway `web` service, Dockerfile build,
      tracking `main`, single replica in `ams`; deploys on merge and runs
      `db:prepare` via `bin/docker-entrypoint` before booting).
* [x] PostgreSQL (Railway `postgres` service, `postgres:16`, storing data
      on the `scenecore-postgres-data` volume — see the Database section
      below).
* [x] Storage (Railway Volume `scenecore-active-storage`, 500MB, mounted
      at `/rails/storage`; see 1.3).
* [x] Background jobs (`:async` in-process, matching a single replica with
      no app-owned jobs — see Phase 14, Background jobs, for the reasoning
      and the trigger for moving back to Solid Queue).
* [ ] Domain. Only Railway's generated
      `web-production-4c75.up.railway.app` exists; no custom domain is
      configured (`customDomains: []`). Needs a product decision on the
      real domain before launch.
* [x] HTTPS (`force_ssl` + `assume_ssl` enabled in `production.rb`;
      verified live: `http://` returns 301 and `/up` returns 200 over
      HTTPS).

### Environment

* [x] Production environment variables (`APP_HOST`, `DATABASE_URL`,
      `PORT`, `RAILS_ENV`, `RAILS_MASTER_KEY`, `ACTIVE_STORAGE_PATH` set
      on `web`; verified against the live environment and listed in
      `docs/deployment.md`).
* [x] Secrets configured securely (credentials are encrypted in
      `config/credentials.yml.enc`, with `RAILS_MASTER_KEY` supplied as a
      Railway variable rather than committed).
* [x] No secrets in repository (`config/master.key` and `.env` are
      gitignored and were never committed — checked the full history, not
      just the working tree; `.kamal/secrets` is the stock template with
      no real values).

### Database

2026-09-15: **the production database had no persistent storage, and now
does.** The `postgres` service was running the raw `postgres:16` image
with `volumeMounts: []`, writing to the container filesystem — any restart
or redeploy destroyed every user, band, album, post and follow. It now
stores data on the `scenecore-postgres-data` volume (500MB) mounted at
`/var/lib/postgresql/data`, with `PGDATA` pointed at a `pgdata`
subdirectory of that mount.

That subdirectory matters: a Railway volume arrives with a `lost+found`
directory, so `initdb` refuses to use the mount point directly and the
service crash-loops. The first attempt here did exactly that; setting
`PGDATA=/var/lib/postgresql/data/pgdata` fixed it. Full procedure,
including the dump/restore commands that actually work against this setup,
is in `docs/deployment.md`.

Verified by restarting the `postgres` service and confirming the schema
(17 migrations) and the existing user row both survived — the operation
that would previously have wiped the database.

* [x] Production migrations reviewed (17 migrations, none destructive — no
      `drop_table`, `remove_column` or `change_column`; they apply
      automatically via `db:prepare` in `bin/docker-entrypoint`, verified
      working in the deploy logs when `AddEnumCheckConstraints` shipped).
* [x] Backup configured (2026-09-15). Railway's own scheduled-backup
      feature is not available on this account (its docs call it "still
      under development"), so this is a `postgres-backup` service:
      `postgres:16-alpine`, `cronSchedule` `0 3 * * *`, running `pg_dump`
      to the dedicated `scenecore-backups` volume and keeping the 7 most
      recent dumps. Deliberately a *separate* volume from the database's
      own, so a corrupted database volume does not take the backups with
      it. Verified by running it and confirming a real 43KB dump lands on
      the volume.
* [x] Restore procedure documented (`docs/deployment.md` has the working
      dump command and the dump → attach volume → restore order). A
      verified dump was taken 2026-09-15; restoring it has not been
      exercised yet, so treat the procedure as documented but untested.

### Monitoring

* [x] Application logs (tagged with request id, written to STDOUT and
      collected by Railway; readable per deployment. Verified while
      debugging production this round).
* [x] Error monitoring (2026-09-15: Sentry via `sentry-rails`, configured
      in `config/initializers/sentry.rb` from `SENTRY_DSN`. It stays
      entirely inactive when that variable is absent, so development, test
      and CI never report or make network calls. `send_default_pii` is off
      — request bodies, cookies and user details are not shipped
      off-platform — and routing/record-not-found errors are excluded as
      bot noise. **Set `SENTRY_DSN` on the Railway `web` service to
      activate it; until then nothing is reported.**)
* [x] Health check (`/up` via `rails/health#show`, excluded from the
      HTTPS redirect and silenced in the logs; verified live returning
      200).
* [ ] Payment monitoring (blocked — Phase 9 skipped).
* [ ] Background job monitoring. Not applicable in a useful sense yet:
      the `:async` adapter has no queue to observe and there are no
      app-owned jobs. Revisit together with the move back to Solid Queue.

### Email

**Nothing is configured.** `production.rb` leaves
`action_mailer.smtp_settings` commented out, so no mail can be delivered
in production. This already matters: Devise's password reset silently
depends on it, and it blocks adding email confirmation for address
changes (see Phase 13, Authentication). Needs a provider decision.

* [ ] Email provider configured.
* [ ] Transactional emails tested.
* [ ] Failure handling tested.

### Webhooks

* [ ] Production webhook URLs configured (blocked — Phase 9 skipped, no
      provider sends webhooks here yet).
* [ ] Signature validation enabled (blocked — same).
* [ ] Idempotency verified (blocked — same).

## Exit criteria

Production infrastructure is documented and can be deployed reproducibly.

---

# 19. Phase 16 — End-to-End Homologation

## Objective

Validate the MVP using realistic scenarios.

## Test Accounts

Create:

* [ ] Platform administrator.
* [ ] Band A administrator.
* [ ] Band B administrator.
* [ ] Fan.
* [ ] Visitor.

## Scenario 1 — Band onboarding

* [ ] Band A requests registration.
* [ ] Platform administrator approves Band A.
* [ ] Band A administrator accesses the dashboard.

## Scenario 2 — Music

* [ ] Band A creates an album.
* [ ] Band A creates a track.
* [ ] Track remains draft.
* [ ] Visitor cannot access draft.
* [ ] Band A publishes track.
* [ ] Visitor can listen.

## Scenario 3 — Followers

* [ ] Fan follows Band A.
* [ ] Fan unfollows Band A.
* [ ] Relationship is correctly updated.

## Scenario 4 — Exclusive content

* [ ] Band A creates follower content.
* [ ] Visitor cannot access it.
* [ ] Fan who follows Band A can access it.
* [ ] Subscriber-only content remains protected.

## Scenario 5 — Commerce

* [ ] Band A creates product.
* [ ] Fan adds product to cart.
* [ ] Fan completes checkout.
* [ ] Payment succeeds.
* [ ] Order becomes paid.
* [ ] Inventory changes correctly.

## Scenario 6 — Multi-band isolation

* [ ] Band A administrator attempts to access Band B.
* [ ] Access is denied.
* [ ] Band A administrator cannot modify Band B.
* [ ] Band A administrator cannot access Band B private files.
* [ ] Band A administrator cannot access Band B financial information.

## Scenario 7 — Subscription

* [ ] Fan subscribes to Band A.
* [ ] Payment is confirmed.
* [ ] Subscription becomes active.
* [ ] Subscriber content becomes available.
* [ ] Subscription is cancelled.
* [ ] Access changes according to the approved business rule.

## Scenario 8 — Tickets

* [ ] Band A creates event.
* [ ] Fan purchases ticket.
* [ ] Ticket is generated.
* [ ] QR code is generated.
* [ ] Ticket is validated.
* [ ] Second validation is rejected.

## Exit criteria

Every critical user journey passes in staging.

---

# 20. Phase 17 — Launch

## Objective

Deploy the approved MVP to production.

## Pre-launch checklist

* [ ] CI green.
* [ ] Tests green.
* [ ] Lint green.
* [ ] Security audit complete.
* [ ] Staging homologation complete.
* [ ] Production environment configured.
* [ ] Database backup verified.
* [ ] Payment provider production configuration verified.
* [ ] Webhooks verified.
* [ ] Email verified.
* [ ] Monitoring verified.
* [ ] Rollback procedure documented.

## Deployment

* [ ] Merge approved changes.
* [ ] Deploy production.
* [ ] Run migrations.
* [ ] Verify health check.
* [ ] Run smoke tests.
* [ ] Verify logs.
* [ ] Verify background jobs.
* [ ] Verify payment integration.

## Exit criteria

The application is operating in production and the critical user journeys work.

---

# 21. Post-Launch

## Objective

Monitor the MVP before adding new functionality.

## First checks

* [ ] Application errors.
* [ ] Authentication failures.
* [ ] Payment failures.
* [ ] Webhook failures.
* [ ] Background job failures.
* [ ] Database errors.
* [ ] Storage failures.
* [ ] User-reported problems.

## Product validation

Monitor:

* [ ] User registration.
* [ ] Band creation.
* [ ] Music publication.
* [ ] Content engagement.
* [ ] Product purchases.
* [ ] Subscription conversion.
* [ ] Ticket purchases.

## Rule

Do not immediately expand the product after launch.

First identify:

* real user problems;
* operational problems;
* payment problems;
* usability problems;
* missing critical functionality.

New features should enter the roadmap only after being evaluated against actual product needs.

---

# 22. Future Features

Features not included in the MVP should be recorded here instead of being implemented opportunistically.

## Candidate Features

* [ ] Scene pages connecting bands, fans, releases, and events — requires
      separate product validation and must not be inferred from the SceneCore
      name alone.
* [ ] Scene-level discovery by genre and location.
* [ ] Cross-band community spaces and scene participation.
* [ ] Recommendations for related bands, releases, events, or scenes.
* [ ] Follower notifications — requested alongside Phase 6, but channel
      (email? in-app?), trigger (new release? new post?), and UI are
      undefined.
* [ ] Fan-facing feed of followed bands' activity — requested alongside
      Phase 6, but what it lists, where it lives, and its acceptance
      criteria are undefined.

Each future feature must eventually receive:

* product justification;
* scope;
* acceptance criteria;
* technical impact;
* dependencies;
* priority.

Nothing in this section is authorized for implementation.

Future proposals must be evaluated first against the product positioning:
whether they strengthen the music-first digital home and the ongoing band–fan
relationship. Feature count or competitor parity alone is not sufficient
justification.

---

# 23. Roadmap Status

Use the following status convention:

* `[ ]` Not started
* `[~]` In progress
* `[x]` Completed
* `[!]
