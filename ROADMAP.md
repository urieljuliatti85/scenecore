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

## Superseded 2026-09-16 — albums link out to Spotify

Approved product change. SceneCore no longer mirrors Spotify's track
listing: importing an album captures its title, cover and Spotify id, and
the album is presented as a cover card that links out with "Listen on
Spotify". There is no per-track record, no embedded per-track player and
no public album page.

The reasoning is the one already in 5.3 — SceneCore does not host audio —
carried to its conclusion. Copying a track listing is mirroring metadata
that goes stale on its own and adds an entity the product does not need;
a link does not.

What this supersedes below: 5.2 (Tracks) entirely, 5.3's per-track link
storage, 5.4's publish cascade, and 5.5 (Player). Publishing is now an
album-level flag with nothing to cascade to. The items stay ticked because
they were built and shipped; this section, not their checkboxes, describes
the system as it stands.

`Track` and its table are deliberately **kept and unused** rather than
dropped: they still hold rows imported under the old behaviour, and
dropping them would be an irreversible migration for a days-old decision.
Removing them is a separate, later task.

Also revised: `docs/database.md` (Albums, Tracks, relationship diagram)
and `docs/product.md` (Journey 3, Music rules, public-page rules).

## Tasks

### 5.1 Albums

An album is a band's release: cover, title, and a link out to Spotify.
(Originally: "An album groups a band's tracks into a release. A track
always belongs to an album — there is no ungrouped track." — superseded,
see above.)

* [x] Album model.
* [x] Album belongs to band.
* [x] Create album (imported from Spotify search; see `AlbumsController`).
* [x] Edit album (2026-09-14: `AlbumsController#edit`/`#update` added,
      scoped to the cover only — title/tracks stay Spotify-import-only).
* [x] Album cover (Active Storage, same validation as `Band#photo` via
      the shared `HasImage` concern; set from the album's edit page).
* [x] Album publication state.

### 5.2 Tracks — superseded 2026-09-16 (see above)

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

Superseded in part 2026-09-16: publishing is still album-level, but there
are no tracks to cascade to. Original decision follows.

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

### 5.5 Player (Spotify embed) — superseded 2026-09-16 (see above)

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

# 9.1 Phase 6.1 — Split Registration (Fan and Band)

Inserted after Phase 6 rather than appended at the end: this phase depends
only on `User`, `Band`, `BandMembership`, and `Follow`, all of which exist
as of Phase 6. It does not depend on Subscriptions, Payments, or Events,
and must not wait for them.

## Objective

Split the free registration flow into two entry paths — Fan and Band —
and introduce `Fan` as an explicit entity, so that the difference between
"someone who follows bands" and "someone who represents a band" is
recorded in the domain instead of being inferred from the absence of a
band membership.

## Product rules

Registration remains free for both paths.

A Fan is active immediately. There is nothing to moderate: a fan does not
publish, does not receive money, and does not claim to represent anyone
else.

A Band enters analysis (`Band#status` = `pending`, already implemented in
Phase 3.4). A band claims a public identity and will eventually monetize,
so a Platform Administrator approves it.

A Platform Administrator is never created through the web. It is granted
from the terminal via a rake task.

## Identity model

`User` remains the single identity and the single authentication subject.
`Fan` and `Band` hang off it:

    User  (authentication — Devise)
     |
     +-- has_one  :fan               profile, active on creation
     +-- has_many :band_memberships  per-band role
     +-- has_many :follows           which bands are followed
     +-- platform_admin: boolean     granted via rake only

One email may be a fan of one band and a member of another at the same
time (confirmed product decision, consistent with `docs/permissions.md`:
"A user may hold membership in more than one band at once"). A drummer
with their own band on SceneCore is still a fan of other bands, and must
not need a second account for that.

This rules out Fan and Band as separate authentication subjects. That
alternative would require Devise to authenticate multiple models,
eliminate `current_user` as a single concept (15 usages across 8 files),
rewrite all 7 policies, and repoint 5 foreign keys currently targeting
`users.id` — while contradicting an approved rule in `docs/permissions.md`.

## Tasks

### 6.1.1 Fan model

* [ ] `Fan` model with `user_id` (FK, not null, unique index).
* [ ] `User has_one :fan`.
* [ ] Migration.
* [ ] Backfill: every existing `User` gets a `Fan`.
* [ ] Model tests.

The table is deliberately created with no attributes beyond the
association. It records that the fan profile exists and gives city,
genres, and preferences a place to live if and when those are approved.
`Follow` remains what records *which* bands are followed. Do not add
speculative columns.

### 6.1.2 Platform administrator rake task

* [ ] `scenecore:admin:grant[email]`.
* [ ] `scenecore:admin:revoke[email]`.
* [ ] `scenecore:admin:list`.
* [ ] Fail with a clear message when the email does not exist — never
      create a user.
* [ ] Record each grant/revoke in `AdminActionLog`.
* [ ] Tests.

This replaces the current situation, in which `platform_admin` has no
write path at all (no rake task, no seed, no screen) and can only be set
by editing the column from `rails console` in production.

`revoke` ships with `grant`, not later: granting without being able to
revoke is worse than the current state.

### 6.1.3 Fan registration path

* [ ] Route for the fan path.
* [ ] Create `User` + `Fan` in one transaction.
* [ ] Redirect to `/discover` on success.
* [ ] No pending state, no approval step.
* [ ] Request tests.

### 6.1.4 Band registration path

* [ ] Route for the band path.
* [ ] Create `User` + `Fan` + `Band` (`pending`) + `BandMembership`
      (`administrator`) in one transaction.
* [ ] Reuse the existing `BandsController#create` logic rather than
      duplicating it.
* [ ] Apply the approved positioning copy: "Use Spotify to get
      discovered. Use SceneCore to build your fan base."
      (`docs/product.md`, ADR-005).
* [ ] Request tests.

The band path also creates the `Fan` record. Whoever registers a band is
a person who may follow other bands; skipping it would produce a user who
cannot follow anyone.

### 6.1.5 Entry point

* [ ] Screen offering the two paths.
* [ ] Both paths clearly free.
* [ ] System test covering both.

### 6.1.6 Behavior during analysis

A band under analysis builds its page; the page is not public until
approved. This is already the behavior of the existing code and must be
verified, not rebuilt:

* [ ] `BandPolicy#show?` — a member sees their own pending band.
* [ ] `PublicBandsController` — only `approved` bands are exposed.
* [ ] Albums and posts are manageable while pending.
* [ ] Tests asserting the above.

A pending band must reach its approval day with bio, photo, and albums
already in place. Blocking the band behind a waiting screen would mean
*adding* restrictions that do not exist today, for a worse outcome.

## Database impact

Additive only. No existing table or column is modified.

    fans
      user_id     FK -> users, not null, unique
      created_at
      updated_at

The unique index makes the relationship one-to-one, which is the intended
rule.

## Authorization impact

None by design. `current_user`, all 7 policies, Devise, and the foreign
keys on `band_memberships`, `follows`, and `admin_action_logs` are
unchanged. Existence of a `Fan` record grants no permission by itself;
authorization continues to be decided by `BandMembership` role per band
and by `platform_admin`.

## Out of scope

Proposed alongside this phase but deliberately excluded, each requiring
its own decision. None is blocked by this phase:

* Verified badge — undecided whether it is the same axis as
  `Band#status` = `approved` or a separate one. Recommendation on record:
  a separate axis with manual review, since "may exist publicly" and "is
  authentically this band" are different judgements.

  Settled 2026-09-16, and it bounds this phase: **registration never asks
  a band to verify itself.** Verification is triggered by a claim against
  the band, or by the band requesting it — never as a step in signing up.
  Whatever the badge design turns out to be, it must not add a step to
  the flow described above.
* Platform commission consent (10% on subscriptions) — belongs to
  subscription activation (Phase 10), not to registration, and requires
  versioned terms plus a per-transaction snapshot of the rate, per
  `docs/payments.md` ("Platform commission must be explicit").
* Audio upload for bands without Spotify — contradicts
  `docs/database.md` ("A track's audio is not hosted by SceneCore") and
  Phase 5.3. Requires its own ADR covering storage cost, copyright
  liability, and protection of paid audio.
* Band dashboard, subscription revenue, subscribers, events, tickets,
  and payout — Phases 9, 10, and 11. Already approved MVP scope; they do
  not belong in the registration flow.

## Exit criteria

* [ ] A visitor can choose between registering as a Fan or as a Band.
* [ ] The fan path produces an active `User` + `Fan` with no pending
      state.
* [ ] The band path produces `User` + `Fan` + `Band` (`pending`) +
      `BandMembership` (`administrator`).
* [ ] One email can be a fan of one band and a member of another
      simultaneously.
* [ ] A pending band is manageable by its members and invisible publicly.
* [ ] `platform_admin` can be granted, revoked, and listed from the
      terminal, and each change is logged.
* [ ] Existing users are backfilled with a `Fan` record.
* [ ] Authorization tests pass with no change to existing policies.

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
confirmation).

2026-09-16: Application section audited and closed — all four items pass,
no fix required; two follow-ups recorded there. **Payments remains the only
open section, and it is blocked on Phase 9 (skipped), so every unblocked
item in this phase is now done.**

One gap found on 2026-09-15 is still open and is no longer blocked: `User`
has no Devise `:confirmable`, so a signed-in user can change their email
with no proof they control the new address. It was deferred because
production had no SMTP; that stopped being true in #74. See Authentication
below.

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

      **Update 2026-09-16: that blocker is gone.** #73 and #74 configured
      SMTP (Resend) and a real message was delivered from production, so the
      confirmation-email flow `:confirmable` needs now exists. This is
      therefore the oldest known, unfixed and no-longer-blocked security gap
      in the app.

      **Approved 2026-09-16 — scope decided, not yet implemented:**

      1. Enable `:confirmable` in **reconfirmable mode only**: a new sign-up
         is *not* required to confirm and signs in immediately, but changing
         an existing email requires confirming the new address before it
         takes effect (Devise holds it in `unconfirmed_email` until then).
         This closes the actual gap — an email changed without proof of
         control — without touching sign-up.
      2. **Backfill `confirmed_at` for existing users** in the same
         migration. Locking real users out over a gap that only concerns
         *changing* an email is disproportionate.
      3. **Requiring confirmation at sign-up is explicitly deferred** to a
         follow-up, tied to the custom domain in Phase 15 (Infrastructure →
         Domain). It is not a preference: production still sends from
         `onboarding@resend.dev`, Resend's test domain, which only delivers
         to the account owner's own address. Requiring confirmation at
         sign-up today would mean anyone who is not the account owner never
         receives the email and cannot get in — a broken sign-up, not added
         friction. Reconfirmable alone works on the current infrastructure,
         because until the domain exists the only person changing an email
         in production is the account owner.

      Still unticked because it is a decision recorded, not code written.

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

2026-09-16: audited. All four items verified against the current tree, the
full git history and the live production environment. No fix was needed —
every check passed — but two observations are recorded below as named
follow-ups rather than being silently ticked off.

* [x] Secrets are not committed. Checked the **full history** (every ref,
      `--diff-filter=A`), not just the working tree. The only
      sensitive-by-name files ever added are `.env.example` and `.env.test`
      (a local `DATABASE_URL` each, no credentials), `.kamal/secrets` (the
      stock template — it reads `config/master.key`, it does not contain a
      value) and `config/credentials.yml.enc` (encrypted, and meant to be
      committed). `config/master.key` is covered by the `/config/*.key`
      ignore rule and has never been committed.
* [x] Environment variables are used correctly. Every secret is read from
      an environment variable (`SMTP_PASSWORD`, `SMTP_USER_NAME`,
      `SENTRY_DSN`, `DATABASE_URL`, `RAILS_MASTER_KEY`) or from encrypted
      credentials (`Rails.application.credentials.spotify`); none has a
      hardcoded fallback. The `ENV.fetch` defaults that do exist are all
      non-sensitive (`MAIL_FROM`, `APP_HOST`, `ACTIVE_STORAGE_PATH`,
      `SMTP_PORT`, `RAILS_LOG_LEVEL`). Optional integrations guard on the
      variable being present (`SMTP_ADDRESS`, `SENTRY_DSN`) and stay
      inactive rather than failing when it is absent.
* [x] Security checks pass. `bin/brakeman` reports 0 security warnings
      across 19 controllers, 10 models and 48 templates; `bin/bundler-audit`
      and `bin/importmap audit` both report no vulnerabilities. All three
      run in CI on every pull request (`.github/workflows/ci.yml`).
* [x] Error pages do not expose sensitive information. Verified against
      **live production**, not just config: `consider_all_requests_local`
      is `false`, and an unknown path returns a real 404 carrying
      `strict-transport-security`, `x-content-type-options: nosniff`,
      `x-frame-options: SAMEORIGIN` and a `secure; httponly; samesite=lax`
      session cookie, with no backtrace, exception class or gem path in the
      body. `PublicBandsController` renders its own `not_found` view with
      `status: :not_found`, so a missing band and a missing page are
      indistinguishable — a draft or unapproved band leaks nothing by being
      absent. Log parameter filtering covers `:passw`, `:email`, `:secret`,
      `:token`, `:_key`, `:crypt`, `:salt`, `:certificate`, `:otp`, `:ssn`,
      `:cvv`, `:cvc` — `:email` is beyond the Rails default.

### Follow-ups identified (not defects, not fixed here)

Neither blocks this phase's exit criteria; both are behaviour changes
rather than audit findings, so they are recorded instead of being made
silently.

* There is no `public/403.html`, and `Pundit::NotAuthorizedError` is
  handled by `ApplicationController#user_not_authorized` with a redirect to
  root plus a flash. Nothing leaks — and where leaking existence would
  matter, `Admin::BaseController` already answers 404 on purpose — but no
  403 response in the app has a page of its own.
* `config.hosts` is commented out in `config/environments/production.rb`
  (the stock `rails new` state), so DNS-rebinding protection is off.
  Harmless while the only hostname is Railway's generated domain; it
  becomes worth setting when the custom domain lands (see Phase 15,
  Infrastructure → Domain).

## Band Identity and Ownership Disputes

Identified 2026-09-16. **Nothing in the system connects a `Band` record to
the real-world band it claims to be.** Ownership is decided by who
registered first, and nothing else.

Concretely, today:

* `Band` validates `name` for presence only — not uniqueness. Two records
  may carry the same band name. `slug` is unique, but `generate_slug`
  resolves a collision by appending `-2`, so the second registrant simply
  gets a different URL.
* Registering a band requires only an authenticated account
  (`BandPolicy#create?` is `user.present?`). Anyone can register any name.
* The Spotify integration cannot help. `SpotifyClient` uses the Client
  Credentials flow — read-only access to the public catalog, with no user
  authorization — so a Spotify artist URL on a band profile proves the
  artist exists, never that the registrant controls it. Copying someone
  else's URL is indistinguishable from owning it.
* There is no claim path. A real band finding an impostor's page has
  nowhere to report it: no form, no route, no model, no concept.
* Platform approval does not close this. `BandsController#approve` decides
  whether a band may exist publicly; it makes no finding about identity,
  and an administrator approving a band has nothing to check authenticity
  against.

The related internal case — members of a legitimate band fighting over
control — is in better shape: `BandMembership`'s last-administrator
invariants prevent a band being left with no administrator, and
`Admin::PrivilegesController` gives a platform administrator a way in.
Worth noting even so that `BandMembershipPolicy` grants every
administrator equal power, with no founder concept, so a recently promoted
member can remove the person who created the band.

### Why this gets worse, not better

* Phase 10 (Subscriptions): once a band's page carries revenue, an
  ownership dispute stops being an embarrassment and becomes a financial
  claim — whoever controls the account receives the money.
* The verified badge proposal (Future Features): a badge granted to an
  impostor is worse than no badge, because the platform then vouches for
  the impersonation.
* Phase 6.1 (Split registration): easier registration means more
  registrations, including wrong ones.

### What is missing

* [ ] A claim path. Decided 2026-09-16: a link in the footer of the
      public band page, labelled **"Claim Your Band"**, opening a form
      that reaches a platform administrator.

      On the public band page rather than only in the global footer, so
      the claim already knows which band it refers to — the claimant
      never types a name — and so it appears at the moment someone is
      looking at the page that is wrong. A global footer link is worth
      adding as well, as a safety net for someone who does not think to
      look there.

      Named "Claim", not "Revoke". The person clicking is asserting that
      the page is theirs, not cancelling someone else's — "revoke" reads
      as deleting your own band and would be clicked by the wrong people,
      or by nobody. "Claim your band" is the label Spotify, Bandcamp and
      Google Business all use for this exact situation.

      Visible to everyone, signed in or not (decided 2026-09-16). A band
      discovering an impostor's page usually arrives from a search result
      or a link, with no SceneCore account and no reason to create one
      before complaining; a sign-in wall at that moment loses exactly the
      claim the feature exists to catch. Control still cannot be
      transferred to someone without an account, so the account is
      required later in the process, not as the price of being heard.

      Two consequences to handle rather than discover:

      * The form is an unauthenticated, public write endpoint — the first
        in the app. It needs rate limiting (see Rate Limiting below) and
        some abuse handling, or it is a free channel for junk aimed at
        platform administrators.
      * An anonymous claim needs a contact route back, so the form must
        collect a way to reach the claimant. That makes it the first place
        the app stores contact details for a non-user, which carries
        retention and privacy questions that a signed-in claim would not.

      What the form collects (decided 2026-09-16), deliberately little:

      * Which band — prefilled from the page the claimant is on.
      * Their role — member / manager / label / other. One line, and it
        already separates a claim from a third party's report.
      * A contact address, since an anonymous claim has no other way back.
      * Where the band lives online — links to its official Instagram,
        Spotify, site or Bandcamp.

      The last field does the real work, and the phrasing matters: it asks
      where the band's official channels are, not "prove it is you". The
      administrator does not have to judge a document; they need somewhere
      to send the verification challenge, and a band's official channels
      are public and checkable by anyone.

      Deliberately **not** collected: identity documents, company
      registration, contracts, trademark filings. Asking for them implies
      the platform performs a legal assessment, which it does not and
      should not, and storing identity documents creates data-protection
      obligations out of proportion to the problem.

      Note: a claim form without a defined evidence standard is an inbox
      nobody knows how to judge. This item is still worth building before
      that is settled — having somewhere for a claim to arrive beats
      having nowhere — but it does not by itself resolve a dispute, and
      it will surface the policy question below rather than answer it.
* [ ] An evidence standard. Decided 2026-09-16: **control of a channel,
      not documentation.** The platform generates a code; the claimant
      publishes it temporarily in the bio of the band's official
      Instagram, Spotify or website; an administrator confirms it is
      there.

      Why this over documents: it is binary (the code is in the bio or it
      is not — no judging whether a signature looks genuine), it resolves
      in minutes rather than days, it is hard to forge (publishing to the
      official Instagram requires controlling the official Instagram), and
      it is the same mechanism the verified-badge proposal needs, so one
      implementation serves both. It also breaks the symmetry that makes
      disputes unresolvable: whoever actually plays in the band controls
      the band's channels; whoever copied the name does not.

      Where channels disagree, the channel the band uses to speak to its
      audience outranks the one it uses to sell: official Instagram and
      Spotify above website and Bandcamp. They are harder to recover once
      lost and more visibly the band's own.

      **Verification is not requested at registration.** A band signing up
      is not asked to verify itself — registration stays as light as Phase
      6.1 describes. Verification is triggered by a claim, or by a band
      asking for it.

      The band-initiated path is a **"Request verification"** action in
      the band panel (decided 2026-09-16), running the same channel-code
      challenge as a claim: the band asks, the platform issues a code, the
      band publishes it in its own official bio, an administrator
      confirms. Same mechanism, different trigger — one defensive (someone
      contested the page), one voluntary (the band wants the badge).

      Two things this must get right:

      * It is an action a band takes *when it wants to*, never a prompt,
        banner or nag in the panel. The moment the panel pushes bands
        toward verification, unverified stops being the normal state in
        practice, whatever the badge design says.
      * It needs a visible state — not requested / awaiting the code being
        published / awaiting review / verified / rejected — or a band that
        asks hears nothing back and asks again. That state is also what
        the administrator's queue reads from.

      Open: whether a rejected request can be retried, and after how long;
      and whether a band already under an unresolved claim can request
      verification at all (it should probably be blocked, since the claim
      is the same question being decided by a different route).

      Keeping verification out of registration puts the cost where the
      doubt is: the vast majority of registrations are what they say they
      are, and charging every band an identity check to catch the rare
      impostor would add friction at the exact step Phase 6.1 is trying to
      keep short. It also means an unverified band is the normal state,
      not a suspicious one — which the badge design has to reflect, or
      absence of a badge becomes an accusation against every band that
      simply never needed one.
* [ ] A documented resolution process. The tools already exist —
      `suspended` status to freeze a disputed page, `Admin::Privileges`
      to transfer control, `AdminActionLog` to record the decision (once
      privilege changes are actually logged, see Audit Logging below).
      What is missing is the process that uses them, not the mechanics.

### When both sides have evidence

The channel-control standard above removes most of this problem: only one
side can publish a code to the band's official Instagram bio. That is not
a coin flip — it is the large majority of cases resolved without anyone
having to judge anything.

What remains are real disputes between real people: a band that split and
left each half holding some of the channels, a former manager who still
controls the Spotify profile, two groups using the same name in different
cities.

Proposed policy for those — **do not resolve them; freeze them**:

1. Suspend the disputed page (`Band#status` = `suspended`, already
   implemented). Nobody publishes, nobody earns, while it lasts.
2. Tell both parties plainly that the platform does not arbitrate
   ownership of an artist name.
3. Wait for agreement between the parties, or a court order.
4. Record every step in `AdminActionLog` (which requires the privilege
   logging in Audit Logging below to exist first).

This is deliberate, not evasive. The platform has no competence, no
mandate and no information to decide who legitimately owns an artist name,
and deciding wrongly is worse for everyone — including the rightful party,
who then has no recourse. It is the posture Bandcamp and Spotify take for
the same reason.

One rule prevents the expensive mistake: **when in doubt, do not
transfer.** Keeping the status quo frozen is reversible; handing the page
to the wrong side gives an impostor the page, the followers and — after
Phase 10 — the revenue.

This is a policy decision rather than a technical recommendation, and it
is recorded here as a proposal awaiting confirmation.

### What freezing costs once there is money

Suspension is close to free today. After Phase 10 it is not: subscribers
are either still being charged for a page nobody can update, or their
subscriptions lapse, and either way someone is owed something. The policy
above has to say what happens to revenue during a freeze — held, refunded,
or paid out to nobody — and that ties directly to the payout model
recorded in Future Features.

That is the reason to settle this before Phase 10 rather than alongside
it: afterwards, the first dispute is also the first financial incident.

## Audit Logging

Identified 2026-09-16 while analysing band-ownership disputes.
`AdminActionLog` exists and is written in exactly two places
(`BandsController#log_admin_action` for approve/reject/suspend/reactivate,
and `Admin::AlbumsController#unpublish`). Several platform-administrator
actions of equal or greater consequence leave no trace at all.

The most consequential gap is band-privilege changes.
`Admin::PrivilegesController#create` lets a platform administrator grant
band-administrator rights over **any** band to **any** user, including
someone who is not a member of it, and `#update` lets them change an
existing member's role. Neither writes a log entry. That is the exact
mechanism by which control of a band would change hands in an ownership
dispute — and there is currently no way to reconstruct, after the fact,
who moved it or when.

* [ ] Log `Admin::PrivilegesController#create` (grant band-administrator
      privileges).
* [ ] Log `Admin::PrivilegesController#update` (change a member's role).
* [ ] Log category create/update/destroy (`Admin::CategoriesController`)
      — lower stakes, but it is platform-structural data that bands
      depend on and it is currently unaudited.
* [ ] Decide whether band-side membership changes are audited too.
      `BandMembershipsController` (invite, change role, remove) is a band
      administrator acting within their own band, not a platform
      administrator — arguably a different kind of record, and
      `AdminActionLog` may be the wrong home for it. Not obviously in
      scope; recorded so the decision is explicit rather than accidental.

* [ ] No way to read the log. `AdminActionLog` has no index action, no
      view and no route — entries are written and never surfaced, so
      auditing today means opening a Rails console against production.
      A read-only admin screen would make the existing entries useful;
      without one, adding more writes improves the record but not the
      ability to use it.

None of this depends on an unbuilt phase or an unapproved feature: it is
missing auditing on controllers that ship and run today. It becomes more
urgent alongside Phase 10 (Subscriptions), when control of a band also
means control of its revenue.

## Rate Limiting

Approved 2026-09-16, **both items implemented 2026-09-16**. Uses Rails'
built-in `rate_limit` (Rails 8.1, already the version in use — no new
dependency).

Correcting this section as first written: it said no rate limiting existed
anywhere in the codebase. `ContactMessagesController` already had one
(`to: 5, within: 1.hour`); the two were written in parallel. That does not
change the finding about the authentication endpoints, and its store
handling is the pattern both controllers below reuse.

* [x] Sign-in (2026-09-16). New `Users::SessionsController`, with
      `rate_limit to: 10, within: 3.minutes, only: :create`. Before this,
      `/users/sign_in` accepted unlimited attempts, so password
      brute-force was viable against any account, a platform
      administrator's included.

      Keyed by client, not by submitted email: limiting a named account
      is what `:lockable` does, and that is itself a denial-of-service
      vector (see below). A spec covers the case that matters — one
      client walking many different addresses — not just repeated
      failures on a single login.

* [x] Password reset (2026-09-16). New `Users::PasswordsController`, with
      `rate_limit to: 5, within: 1.hour, only: :create`. Without it the
      endpoint was a free email generator pointed at any address — a real
      cost since SMTP was configured (#74, commit f13314e), and a way to
      bury someone's inbox using SceneCore's own sending reputation.

* [x] Account enumeration (2026-09-16, not originally in this section).
      `config.paranoid` was commented out, so password recovery answered
      differently for a known and an unknown address — handing an
      attacker a verified list of addresses to point the sign-in limit
      at. The two findings compound, so it was fixed in the same pass.
      Note it does not affect `registerable`: sign-up still reports an
      address as already taken, which Devise cannot avoid without
      breaking registration.

Both limiters keep counters in their own `MemoryStore` rather than
`Rails.cache`, which is `:null_store` in test — a limit stored there would
silently do nothing in the suite, making the protection untestable. The
process-memory caveat below still applies to both.

The third application, comment creation (`to: 10, within: 1.minute` plus
`to: 100, within: 1.hour`), is recorded under Future Features and is only
reachable if band-moderated comments are approved. It does not belong to
this phase.

Sign-in and password reset are done. Comments remain, and only exist if
that feature is approved.

### Not the same thing: Devise `:lockable`

`:lockable` is listed as available but not enabled in `app/models/user.rb`.
It solves an adjacent but different problem: it locks *an account* after N
failed attempts, whereas rate limiting blocks *a client* regardless of
which account is being targeted. Against distributed brute-force — many
addresses, one account, or one address walking many accounts — rate
limiting is what works. Enabling `:lockable` is also a denial-of-service
vector in itself: anyone who knows an email address can lock that account
out by failing on purpose. The two can coexist, but rate limiting is the
one recorded here; `:lockable` is not proposed.

### Caveat: counters live in process memory

`rate_limit` stores its counters in the Rails cache store, and production
uses `:memory_store` (`config/environments/production.rb`, a deliberate
choice for a single web replica). Two consequences:

* Restarting the server resets every counter. A Railway deploy clears all
  limits.
* If a second replica is ever added, the effective limit doubles — each
  process counts its own. The comment already in `production.rb` warns
  about this for cache and queues; it applies to rate limiting too.

This is not a reason to skip it. A limit that resets on deploy still
blocks the attack currently in progress, and is far better than none. It
just should not be mistaken for a strong guarantee. Moving to Solid Cache
(the gem is already in the Gemfile) fixes both at once, and `production.rb`
already flags that as the thing to do when a second replica appears.

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

### Band panel layout: albums and posts as cards

Decided 2026-09-16. `bands/show.html.erb` currently renders every album
with all of its tracks inline, and every post with its full body. Both
become cards, each linking to a screen of its own.

This is not a new feature and does not expand the MVP: the public side
already works exactly this way (`PublicBandsController#show` lists albums,
`#album` shows the tracks at `/:slug/albums/:id`), so this brings the
management area to parity with a pattern the app already uses.

* [x] Albums render as a card — cover, title, status, track count —
      linking to an album screen listing that album's tracks.
* [x] Posts render as a card rather than the full body inline, linking to
      a post screen.
* [x] `AlbumsController#show` plus route and view. The management
      controller currently has `new`, `edit`, `update`, `search`,
      `create`, `publish` and `unpublish` but **no `show`** — tracks exist
      only inside the band view today.
* [x] `AlbumPolicy#show?`. It does not exist, and `ApplicationPolicy`
      denies by default, so without it the album screen 403s for the
      band's own members. The default fails safe rather than leaking, but
      it has to be written deliberately.
* [x] Equivalent screen and policy for posts.

Decided 2026-09-16: publish/unpublish/edit stay on the card, and are
repeated on the album/post screen. The card keeps one-click access to the
actions a band uses most.

Implemented 2026-09-16.

This was expected to shrink the authorization N+1 described below. **It
did not** — measured on a band with 4 albums of 10 tracks and 3 posts,
the page went from 26 queries to 27. The earlier estimate (roughly 220
policy queries dropping to 20) was wrong: it was read from the code
rather than measured, and it missed that the per-record policies resolve
`record.band` from an already-loaded association, so the tracks were
never issuing a query each. The layout change stands on its own merits;
it is not a performance fix, and the N+1 items below are unaffected.

### Band panel query patterns

Identified 2026-09-16 while analysing proposed band-panel widgets (see
Future Features → Band panel widgets). Distinct from the N+1 fixed on
2026-09-15 above, which was about `album.tracks` discarding its preload;
this is about authorization. Recorded, not fixed — none of it is urgent
at current volume, but it should be addressed **before** new widgets are
added, because the first item gets worse with each one rather than merely
bigger.

* [ ] Authorization N+1 in `bands/show.html.erb`. `AlbumPolicy` and
      `PostPolicy` each resolve membership with
      `record.band.band_memberships.exists?(user_id:)`, and Pundit
      memoizes per record, so every album and post instantiates its own
      policy — all asking the identical question, "is this user a member
      of this band?". `BandPolicy` memoizes correctly (`@membership ||=`),
      which does not help, since the memoization is per policy instance.

      The card layout above reduced how many records the page renders but
      did **not** fix this: measured at 26 queries before and 27 after,
      because the per-record policies resolve `record.band` from an
      already-loaded association rather than querying for it. The
      redundant work is real but smaller than a code reading suggests —
      measure before fixing, and do not assume the estimate.

      The fix is cheap and local — resolve the membership once per request
      and have the policies consult that, changing where the answer comes
      from rather than the authorization rules themselves.

* [ ] No pagination anywhere on the panel. The band page loads every
      album and post the band has, and the album screen every track,
      all unbounded. Fine at ten posts, wrong at five hundred. Not worth
      doing until there is a band large enough to notice.

* [ ] `Band#followers_count` calls `followers.size` with no counter
      cache, emitting a `COUNT` per call. Same shape as the
      `public_bands#index` inefficiency recorded above, and worth fixing
      in the same pass if a counter cache is introduced.

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
      configured (`customDomains: []`). **No domain has been registered
      yet** (2026-09-15), so this is a launch-time item, not an
      infrastructure gap — nothing else is waiting on it except real-user
      email (Resend requires a verified sending domain, see Email below).
      The generated Railway domain serves the app over HTTPS in the
      meantime.

      **Blocked on this:** requiring email confirmation at sign-up. Until a
      verified sending domain exists, Resend's test sender only delivers to
      the account owner, so confirmation at sign-up would lock out every
      other user. See Phase 13, Authentication, for the approved
      reconfirmable-only scope shipping ahead of it.
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

2026-09-15: production was not merely missing mail config — it was
actively broken. `delivery_method` defaulted to `:smtp` against
`localhost:25` (nothing listening) with `raise_delivery_errors` defaulting
to `true`, so **"forgot my password" returned a 500** rather than failing
quietly. Both sender addresses were also still the generated placeholders
(`please-change-me-at-...@example.com`, `from@example.com`), which every
provider rejects.

Delivery is now guarded on `SMTP_ADDRESS`: unset, nothing is attempted and
nothing raises; set, mail goes over SMTP with errors surfaced. Senders come
from `MAIL_FROM`.

* [x] Email provider configured (2026-09-15: Resend over SMTP, credentials
      on the Railway `web` service. Note `SMTP_PORT` is **2587** — Railway
      blocks 587 and 465, verified from inside the container; see
      `docs/deployment.md`).
* [x] Transactional emails tested (a real message was sent from production
      and delivered — `SENT OK`, not just a green config check).
* [ ] Failure handling tested. Not exercised: what a user sees when Resend
      is down or rejects a message. `raise_delivery_errors` is on once SMTP
      is configured, so a failure currently surfaces as a 500 on the
      password-reset request — worth handling before real users depend on
      it.

**Still not usable by real users.** The sender is `onboarding@resend.dev`,
Resend's test domain, which only delivers to the account owner's own
address. Real delivery needs a verified domain in Resend, which wants the
custom domain still open in Infrastructure above.

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
* [ ] Notifications and a band inbox — partially specified 2026-09-16.
      Decided: the band panel gets an inbox, and the global navigation
      gets a bell indicator announcing unread notifications. This is a
      cross-cutting feature, not a sub-item of comments: an inbox and a
      bell are infrastructure that any future notification source (a new
      follower, a comment, a subscription, a ticket sale) would feed
      into, so it must not be designed around comments alone.

      Still undefined: which events produce a notification; whether
      notifications are in-app only or also email (the original Phase 6
      request left channel, trigger, and UI undefined, and that gap is
      only partly closed); read/unread semantics; retention; whether the
      bell is band-scoped or user-scoped. That last one matters most and
      has no obvious default — a user who administers two bands and
      follows ten others has notifications from several contexts, and
      `BandMembership` is per band while the navigation bar is per user.

      Note on scope: the band panel this inbox would live in does not
      exist yet. A band dashboard was proposed alongside Phase 6.1 and is
      recorded as out of scope there; most of its widgets depend on
      Phases 9-11. The two should be scoped together if either is
      approved.
* [ ] Fan-facing feed of followed bands' activity — requested alongside
      Phase 6, but what it lists, where it lives, and its acceptance
      criteria are undefined.
* [ ] Verified band badge — proposed alongside Phase 6.1. Undecided
      whether it is the same axis as `Band#status` = `approved` or a
      separate one. Recommendation on record: a separate axis
      (`verified_at`) with manual review, because "may exist publicly"
      and "is authentically this band" are different judgements with
      different criteria. A Spotify artist ID can be shown to the
      reviewer as a signal but does not prove ownership — `SpotifyClient`
      uses Client Credentials (read-only public catalog access), so a
      Spotify URL proves the artist exists, never that the registrant
      controls it.

      Scope it together with Phase 13 → Band Identity and Ownership
      Disputes. Verification is the mechanism that would close that gap,
      and a badge granted without proof of control would make it worse
      rather than better: the platform would be vouching for whoever
      registered first.

      Decided 2026-09-16: verification is **never** requested at
      registration. It is triggered by a claim, or by a band asking for
      it. Two consequences for the badge design: registration stays as
      short as Phase 6.1 requires, and **unverified is the normal state**,
      not a suspicious one. Most bands will never have had any reason to
      verify, so the absence of a badge must not read as an accusation —
      which rules out any treatment that marks unverified bands as
      doubtful rather than simply not marking them at all.
* [ ] Platform commission consent (10% on subscriptions) — proposed for
      registration; belongs to subscription activation (Phase 10)
      instead, since a band has no subscriptions at registration time.
      Requires versioned terms with a record of which version was
      accepted, the rate stored as data rather than a constant, and a
      per-transaction snapshot of the rate applied.
* [ ] Automatic web search for album artwork — proposed 2026-09-16 as
      "update the artwork and the source can be anywhere: the system
      searches the web and updates the cover". Two narrower paths were
      built instead (refetch from Spotify, and attach from a URL the band
      supplies), leaving this as the open question.

      **The blocker is not technical.** Album artwork is a copyrighted
      work. Today SceneCore hosts no artwork that was not either uploaded
      by the band or served by Spotify's API under its terms. A search
      that crawls the web and copies an image into storage changes that:
      the platform starts hosting files of unknown provenance and becomes
      a takedown target. It is the same class of decision as audio upload
      below, and deserves the same treatment — its own ADR, not a
      feature slice.

      Two practical problems beyond the legal one. It needs a search
      provider (Google Images, Bing, MusicBrainz/Cover Art Archive),
      which is a new dependency and new credentials. And text search
      misidentifies: a band with a common name gets another band's cover,
      and without visual confirmation the mistake is discovered on the
      public page.

      The shipped alternative sidesteps both: the band supplies the URL,
      so it picks the image and the rights question stays with whoever
      holds them. If this is revisited, Cover Art Archive is the
      candidate worth evaluating first — it is purpose-built for this,
      keyed by release rather than by text, and its licensing is explicit.

* [ ] Audio upload for bands without Spotify — contradicts
      `docs/database.md` ("A track's audio is not hosted by SceneCore")
      and Phase 5.3 ("no file upload"). Requires its own ADR covering
      storage cost, copyright liability, and protection of paid audio
      against direct download. Cheaper alternative to evaluate first:
      manual album entry with an external link, keeping audio off
      SceneCore.
* [ ] Band payout model — how subscription revenue reaches the band.
      Open questions: managed accounts/split (recommended) versus the
      platform collecting and transferring (likely regulatory exposure);
      per-transaction versus monthly cycle; chargeback reserve period;
      KYC requirements, which would add fiscal data to the band's
      onboarding at monetization time rather than at registration.
* [ ] Event and ticket integration versus first-party ticketing —
      proposed as "integration" alongside Phase 6.1, but Phase 11
      (11.2-11.5) specifies first-party ticketing with batches, QR
      codes, and check-in. These are different products with different
      costs and liabilities; the choice is undecided.
* [ ] Band panel widgets — analysed 2026-09-16. The panel itself is not
      a new feature: `app/views/bands/show.html.erb` already is it,
      reached at `/bands/:id`, authorized by `BandPolicy#show?`, and
      already listing albums (with publish/unpublish/edit), tracks, posts
      (with status and visibility) and member management. Exclusive
      content is already there too — what is missing is not the panel but
      the `subscribers` visibility being reachable, which is Phase 10.

      Requested widgets and what each is actually blocked on:

      * Albums added — already built.
      * Exclusive content — already built; `subscribers` blocked on
        Phase 10.
      * Comments moderation — blocked on the comments proposal above
        being approved.
      * Subscribers — Phase 10.
      * Subscription revenue — Phases 9 and 10, and drags the payout and
        commission decisions with it.
      * Events, tickets — Phase 11.
      * "Request verification" — a band-initiated action, decided
        2026-09-16. Depends on the verified-badge proposal below and on
        Phase 13 → Band Identity and Ownership Disputes, which define the
        challenge it runs. Not a widget showing data: an action plus the
        state of the request.

      Slice it by dependency rather than building it as one item, or the
      whole panel blocks on its most distant piece (revenue, which needs
      a payment provider, a split model and a payout decision).

      **The one widget that depends on nothing, and is worth more than it
      looks: followers and 30-day follower retention.** `Follow` has
      existed since Phase 6 and carries `created_at`, and
      `Band#followers_count` is already implemented and already shown on
      the public page — but not in the band's own panel. ADR-006 makes
      30-day follower retention the primary MVP metric, and today that
      metric is not visible to anyone: not the band, not the platform. It
      exists only as a definition in a document. Surfacing it needs no new
      table and no unbuilt phase, and it is what makes ADR-006 operable.

      Before more widgets are added to that screen, see Phase 14 →
      Band panel query patterns. The view has an authorization N+1 that
      is multiplicative, not additive: each new widget makes it worse
      rather than merely adding to it.

      One open layout question, deliberately not decided: the screen
      currently mixes band management with platform moderation (the
      approve/reject/suspend buttons live on the same page). Whether it
      stays one screen or becomes sections
      (`/bands/:id/dashboard`, `/bands/:id/comments`) should wait until
      it actually hurts — splitting early is the premature abstraction
      `CLAUDE.md` warns against.
* [ ] Band-moderated comments on posts — proposed 2026-09-16.
      **Conflicts with approved scope:** `docs/product.md` (§4, "Out of
      MVP Scope") excludes "Fan-to-fan messaging or generic social
      posting (likes, comments, feeds)". That list is qualified as
      requiring "separate product validation and explicit approval (see
      ADR-005)", so this is a proposal awaiting that approval, not an
      authorized feature. Promoting it to a roadmap phase requires
      amending `docs/product.md` and recording an ADR, so the two
      documents do not contradict each other.

      The distinction that makes it worth considering: what the product
      spec excludes is fan-to-fan social mechanics — a public square
      where fans talk to each other. What is proposed here is fan-to-band
      conversation anchored to a specific band's post, under that band's
      control. It is the first mechanism in the system that lets a fan
      *respond*; today the relationship is one-directional (band
      publishes, fan follows). Against ADR-006 (retained followers as the
      primary MVP metric), giving a fan a reason to return is one of the
      few plausible retention mechanisms that does not require building a
      social network — but that is a hypothesis, not validation.

      Product decisions already made (2026-09-16), should this be
      approved:

      * Post-moderation with auto-hide on report. A comment is created
        visible; the band hides it afterwards if it wants to; and a
        reported comment is hidden automatically, without waiting for
        anyone, until the band or a Platform Administrator restores or
        confirms it.

        Pre-moderation was considered twice and rejected both times. It
        makes the band act on every comment, including the twenty-nine
        good ones, to catch the one that is a problem — and bad content
        is the exception, not the rule. A queue nobody has time to work
        does not protect the page; it silences it. The bands that most
        need comments (small ones, building a relationship) are exactly
        the ones without a community manager, so the feature would ship
        switched off in practice.

        Auto-hide on report is what makes post-moderation safe enough
        without that cost: the platform acts at the first signal instead
        of the band acting on everything. For a band receiving thirty
        comments of which one is abusive, pre-moderation costs thirty
        actions and hides the twenty-nine good ones meanwhile; this costs
        one action and exposes the bad one only until the first report.

        It composes two things already decided rather than adding a
        mechanism: the `hidden` state (chosen over hard deletion) and the
        reporting path. A report simply triggers `hidden` automatically
        instead of only queueing for human review.

        Two risks, both manageable. Reporting can be weaponised to hide
        comments: mitigated by requiring the reporter to be a follower
        (the same bar as commenting) and by making the band's restore a
        single action — hiding wrongly is cheap and reversible, leaving
        an attack up is not. And the threshold is a guess: start at a
        single report and recalibrate against real data, the same posture
        as the rate-limit numbers. A threshold of two or three is more
        robust on a high-traffic post and too slow on a small band.
      * Only followers may comment, regardless of the post's
        `visibility` (`public`/`followers`/`subscribers`). Minimal
        friction, eliminates drive-by spam, and reinforces `Follow` as
        the door to the relationship.
      * The band removes comments on its own posts. Authorization by
        `BandMembership`, consistent with every other band-scoped
        action — never a global flag.
      * A reporting path escalates to the Platform Administrator, whose
        moderation role is already described in `docs/product.md` §2
        ("Administrator"). `AdminActionLog` already exists and is already
        used for moderation actions, so escalation has a home.

      Resolved 2026-09-16:

      * Band removal hides the comment (soft `hidden` state), never a
        hard delete. This preserves the evidence a Platform
        Administrator needs when a comment is reported, and keeps
        moderation auditable.
      * A fan may edit and delete their own comment. A fan's own
        deletion is distinct from a band hiding a comment: the two are
        different actions by different actors and must be distinguishable
        in the data, so a band cannot be shown as having moderated
        something the fan simply withdrew. Whether a fan's edit or delete
        is limited to a time window is not decided.
      * A band may block a specific fan from commenting on its posts, in
        addition to acting on individual comments. The block is per band,
        never platform-wide — a fan blocked by Band A must remain able to
        comment on Band B. This follows the band-isolation rule in
        `docs/permissions.md` and requires its own table plus a policy
        check on comment creation. Whether blocking also hides the fan's
        existing comments is not decided.
      * Visitors see comments read-only, consistent with how public posts
        already work. Commenting still requires being a follower, so a
        visitor reads but cannot reply.
      * The band panel gets a Comments area listing the band's posts with
        their comments, reported ones first, offering hide/restore and a
        list of blocked fans with an unblock action. Named "Comments",
        not "Approve comments": the screen shows what exists, it does not
        gate whether comments appear. Nothing in it is a queue the band
        must clear for the feature to work — an unattended panel still
        leaves a working comment section, with reported content already
        hidden automatically.

        This is a section of the band panel that already exists
        (`app/views/bands/show.html.erb`, reached at `/bands/:id` and
        authorized by `BandPolicy#show?`), not a new product surface. See
        the band-panel note below for what that screen needs before more
        widgets are added to it.

      Still open:

      * Whether a fan's edit/delete is time-limited, and whether a band's
        block retroactively hides that fan's existing comments.

      Rate limiting (decided 2026-09-16). Comment creation is limited in
      two layers, using Rails' built-in `rate_limit` (Rails 8.1, already
      the version in use — no new dependency):

          rate_limit to: 10, within: 1.minute, only: :create
          rate_limit to: 100, within: 1.hour, only: :create

      The per-minute limit stops scripted bursts; the per-hour limit
      stops slow abuse that stays under it. Ten per minute is generous
      for human conversation and still blocks automation. The numbers are
      an informed starting point, not a measurement — recalibrate against
      real traffic.

      Caveat: `rate_limit` stores its counters in the Rails cache store,
      and production currently uses `:memory_store`
      (`config/environments/production.rb`, a deliberate choice for a
      single web replica). So counters reset on every deploy or restart,
      and if a second replica is ever added the effective limit doubles,
      since each process counts separately. This is still worth doing —
      a limit that resets on deploy still stops an attack in progress —
      but it is not a strong guarantee. Moving to Solid Cache (the gem is
      already in the Gemfile) fixes both, and is already flagged in
      `production.rb` as the thing to do when a second replica appears.

      Two higher-priority applications of the same mechanism — sign-in
      and password reset — were approved on 2026-09-16 and are recorded
      under Phase 13 (Security Audit) → Rate Limiting. Neither depends on
      comments being approved, and sign-in should ship first: it closes a
      live brute-force vector, whereas these limits protect a feature that
      does not exist yet.

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
