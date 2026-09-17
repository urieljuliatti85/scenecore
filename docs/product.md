# Product Specification

## 1. Product

### Name

SceneCore

### Description

A music-first platform where independent bands create a digital home, publish
music and content, sell merchandise and tickets, offer subscriptions, and
maintain a direct, ongoing relationship with their fans.

### Product Promise

**Your band. Your fans. Your home.**

### Core Product Question

SceneCore must not rely on “everything for your band in one place” as its main
differentiator. Bandcamp, Patreon, Spotify, and other services already solve
important parts of this problem well.

The strategic question is:

> Which band experience does SceneCore make significantly better?

The answer to test is:

> SceneCore makes the ongoing relationship between an independent band and its
> fans significantly better by giving that relationship a music-first digital
> home.

### Problem

Independent bands may be discovered on one service, publish content on another,
sell elsewhere, and communicate with fans through still more channels. The
central problem is not only fragmented tooling: it is that the relationship
between band and fan remains fragmented, rented, and difficult to sustain.

### Solution

SceneCore gives each band a music-first digital home that connects its identity,
music, content, commerce, subscriptions, and events into a continuous fan
journey.

The idea behind SceneCore isn't simply to be "just another social network for bands." The service creates a direct relationship between band ↔ fan ↔ content ↔ purchase ↔ event.

In practice:

Today, a band might need several different platforms:

Instagram → promotion and relationship building
Spotify → music
Patreon → exclusive content
Own store/Bandcamp → products and music
Sympla/Eventbrite → events and tickets
WhatsApp/Discord → community
Other tools → payments and subscriptions

The problem is that these experiences remain separate.

SceneCore proposes:

SCENECORE
│
┌───────────────┼────────────────┐
│ │ │
FAN PLATFORM
│ │ │
├─ Music ├─ Discover ├─ Payments
├─ Posts ├─ Listen ├─ Subscriptions
├─ Content ├─ Follow ├─ Requests
Products ├─ Support ├─ Transfers

Events ├─ Purchase ├─ Tickets

Subscription └─ Participation └─ Administration
For the band

The service offers an operational hub for your relationship with your fans.

The band can:

create their page;
publish music;
publish exclusive content;
gain followers;
create products;
sell products;
create subscriptions;
create events;
sell tickets;
track their relationship with fans.

In other words, instead of thinking:

"Where do I publish this?"

the band gains a central place for its presence within SceneCore.

For the Fan

The solution is even simpler:

Discover → Listen → Follow → Keep up with → Support → Buy → Participate.

The fan doesn't necessarily need to leave the band's experience to perform each of these actions.

For example:

Band page

↓ Listen to music

↓ Liked it?

↓ Follow band

↓ View exclusive content

↓ Subscribe

↓ Buy t-shirt/vinyl

↓ View next show

↓ Buy ticket

This creates a continuous journey, instead of several disconnected experiences.

And there's a second important solution:

SceneCore also solves a problem of the platform itself: organizing this entire operation consistently.

For example:

Fan

│

├── follows → Band

│

├── subscribes → Subscription

│

├── buys → Order

│

├── attends → Event

│

└── consumes → Content

Meanwhile:

Band

│

├── publishes → Music

├── publishes → Content

├── sells → Product

├── creates → Subscription

└── creates → Event

And the system controls the rules for access, payments, orders, subscriptions, Transfers and isolation between bands.

This is particularly important because the document defines SceneCore as a multi-band platform, and even stipulates as a requirement that one band cannot access another's data.

So what's the solution in a sentence?

I would put it like this:

SceneCore gives independent bands a music-first digital home where they can
build and sustain a direct relationship with their fans through music, content,
commerce, subscriptions, and events.

Or, thinking more as a service proposition:

SceneCore is the place where a band not only publishes its music, but builds and monetizes its direct relationship with its followers.

And this helps to make it clearer what is being sold: it's not just software for bands. It's an infrastructure to transform fan attention into relationships and relationships into financial support, all within a single platform.

### Primary MVP Metric

The primary metric for the MVP is **retained followers**: the percentage of a
band's followers who are still following after 30 days (i.e., have not
unfollowed).

This is chosen over raw follow count because following is a single,
low-friction action and does not by itself demonstrate an *ongoing*
relationship — the product promise this metric must validate. Retention
after a fixed window is a proxy for durability: it is measurable today using
the existing `Follow` model (Phase 6) without depending on unbuilt features.

Purchases, subscriptions, and event participation would be stronger signals
of a durable, monetized relationship, but they depend on Phase 8 (Store),
Phase 9 (Payments), and Phase 11 (Events/Tickets), all currently unbuilt or
skipped. Once Phase 10 (Subscriptions) ships, **subscription retention**
(the percentage of subscribers still active after N billing cycles) should
supersede retained followers as the primary metric, since a recurring paid
relationship is stronger evidence of the promise than a free follow.

### Competitive Positioning

SceneCore complements the strongest existing platforms instead of requiring a
band to abandon them.

| Platform | Main problem solved | SceneCore relationship |
| --- | --- | --- |
| Spotify | Discovery, streaming, and audience growth | A discovery channel that can lead listeners to the band's SceneCore home |
| Bandcamp | Direct sales of music and merchandise | A commerce benchmark and possible complementary purchase channel |
| Patreon | Memberships and exclusive creator content | A membership benchmark; SceneCore remains music-first and band-centric |
| SceneCore | Ongoing relationship between band and fan | The band's persistent digital home |

The intended strategic flow is:

Discovery on Spotify, social media, shows, or elsewhere → the band's SceneCore
home → follow and ongoing relationship → support through purchases,
subscriptions, content, community, and events.

SceneCore should therefore say:

> Use Spotify to get discovered. Use SceneCore to build your fan base.

It should not say:

- “Stop using Spotify, Bandcamp, or Patreon.”
- “Everything for bands in one place” as the sole differentiation.
- “Bandcamp, but with more features.”
- “The social network for music scenes” before that strategy and product scope
  have been explicitly validated.

### Music-first, not streaming-first or content-first

Music establishes the band's identity and anchors the experience, but SceneCore
does not compete by hosting a larger streaming catalog. Content, subscriptions,
commerce, and events deepen the relationship around the music; they are not
independent feature silos.

The primary product outcome is not plays, posts, or isolated transactions. It is
a fan who can discover the band, understand it, follow it, support it, buy from
it, and return to it over time.

### The Scene Opportunity

The name SceneCore supports a broader future direction centered on bands + fans
+ musical scenes. This may become especially valuable for independent,
underground, local, and genre-specific communities.

That direction is not yet the MVP. The current product remains a multi-band
platform whose primary unit of experience is the band's digital home and its
direct relationship with each fan. Scene-level discovery, community graphs,
cross-band feeds, recommendations, and social-network mechanics require a
separate positioning decision, validation, scope, and approval.

---

## 2. Target Users

### Visitor

In the MVP defined in the document, the Visitor is the user who is not yet authenticated. Their actions are primarily for discovery and public consumption, without access to private functionalities.

Visitor can
Action Can? Note
Access SceneCore ✅ No login required
Browse bands ✅ Discover bands
Access a band's public page ✅ Public content
View band information ✅ Public profile/page
Listen to public music ✅ As per visibility rules
View public posts ✅ Public content
View band merchandise ✅ Public store
View events ✅ Published events
View ticket information ✅ Before purchasing
Create account ✅ Registration can begin
Log in ✅ Authenticate possible
Follow a band ❌ Requires Fan
Access exclusive content ❌ Requires permission
Subscribe to a band ❌ Requires authentication
Purchase product ❌* The operation must be linked to the authenticated user in the MVP
Purchase ticket ❌* Same logic
Publish content ❌ Requires Band
Manage band ❌ Requires Permission
Manage products/events ❌ Requires permission

The document explicitly defines the Visitor, Fan, Band, and Admin roles, and places the responsibility on the product to define the journeys for each.

The Visitor's Journey

I would structure it like this:

VISITOR

│

├── Discover bands
│ ↓

├── Enter the band's page

│ ↓

├── Get to know the band

│ ↓

├── Listen to public music

│ ↓

├── View public posts

│ ↓

├── View products

│ ↓

├── View events

│ ↓

└── Create an account

↓

FAN

The important point is that the Visitor should not be treated as a limited Fan.

This represents the gateway to SceneCore:

Discover first. Register when there's a reason.

For example, a visitor might arrive via a band's page, listen to a song, and browse public content. When they want to follow the band, access exclusive content, or provide financial support, they then proceed to the authentication flow.

This also keeps the MVP simple and consistent with the project's rule of not creating functionalities beyond the defined scope.

One issue that still needs to be decided in the product.md file is whether the visitor can start a product/ticket purchase without an account and create one only during checkout. The document doesn't finalize this rule.

### Fan

What a SceneCore fan can do

1. Discover the scene

Explore bands, artists, and projects.
Discover releases, events, and local scenes.
Browse by genres, subgenres, and locations.
Find artists similar to those you already follow.

2. Follow artists

Follow bands and artists.
Receive updates on new releases, shows, and activities.
Access the artist's historical profile.

3. Listen to and discover music

Listen to music made available by artists.
Explore discographies.
Save artists and releases of interest.

4. Participate in the scene

Show support for artists.
Interact with published content.
Share discoveries.
Participate in discussions related to the scene.

5. Discover shows

Find nearby events.
See which artists will be playing.
Discover events by city, region, or scene.

Access event information.

6. Build your own profile
The fan profile can function as a kind of map of your relationship with the scene:

FAN
│
├── Artists you follow
├── Saved releases
├── Events of interest
├── Scenes you follow
└── Participation history
The most important point

I would avoid turning the fan into simply another "social media user".

The differentiating factor of SceneCore could be:

The fan doesn't just follow people. They participate in a scene.

For example:

Scene: Crust Punk — São Paulo

SCENECORE
│
┌─────────────┼─────────────┐
↓ ↓ ↓
BANDS EVENTS RELEASES
│ │ │
└─────────────┼─────────────┘
↓
FAN
│
┌──────────┼──────────┐
↓ ↓ ↓
Follow and discover

bands, shows, music

This also helps to clearly separate the actors in the system:

Artist/Band → creates and promotes.
Organizer → creates and manages events.
Fan → discovers, follows, and participates.
SceneCore → connects these parts and gives structure to the scene.

If the intention is for SceneCore to be an underground/independent platform, I would make the Fan one of the central roles in the domain, but with deliberately lean functionalities in the MVP.

### Band

In SceneCore, the Band/Artist is responsible for representing, publishing, and promoting their own presence within the scene.

What the band can do:

1. Create and manage their profile

The band can create its own page with:

Name
Logo/photo
Biography
Genre and subgenres
City/region
Members
External links
Social networks
Contact information

The profile serves as the band's official identity within SceneCore.

2. Publishing Releases

The band can register:

Singles
EPs
Albums
Compilations
Demos

Each release can contain:

Release
├── Title
├── Cover Art
├── Date
├── Format
├── Description
├── Tracks
└── Links to listen/buy

3. Publishing Music

For each track:

Title
Track Number
Duration
Credits
Player/file when applicable
External links

Not built, and not currently planned: as of 2026-09-16 the implementation
holds albums only and links out to Spotify for listening (see Journey 3
and the Music rules). This per-track description remains the longer-term
product vision, not a statement about the system as it stands.

Thus, SceneCore can also function as a historical catalog of the scene's production.

4. Promoting Shows

The band can:

Indicate that they will participate in an event.

Add their shows to their profile.

Promote upcoming performances.

Maintain a history of performances.

For example:

BAND

│

├── Upcoming shows

│

├── Previous shows

│

└── Related events

5. Publish news

The band can publish updates such as:

New release
New member
Tour
Show announced
Merch
Recording
Changes in the band
Announcements

But I would be careful not to turn this into a generic social media feed.

The post should always be related to the band/scene's activity.

6. Managing Band Members

The band can register who is part of the project:

Band
├── Vocals — João
├── Guitar — Maria
├── Bass — Pedro
└── Drums — Carlos

This also allows for building a history later:

João played in Band A between 2022–2024 and currently plays in Band B.

This type of information can be very interesting for a platform focused on the underground scene.

7. Tracking your presence in the scene

The band could see:

How many people follow the profile.

Which releases are most accessed.

Which events are associated with the band.

Where your band appears within the scene.

But I would put advanced metrics outside of the MVP.

The band's role in SceneCore

I would summarize it like this:

SCENECORE
│
┌─────────────┼─────────────┐
│ │ │
BAND EVENT FAN
│ │ │

↓ ↓ ↓
PUBLISHES ORGANIZES DISCOVERS
│ │ │
└─────────────┼─────────────┘

↓
SCENE

The fundamental difference is:

The band creates and maintains the memory of what is happening.

The organizer moves the scene through events.

The fan discovers, follows, and participates.

And this suggests a fairly clear domain structure for SceneCore:

Artist → Releases → Tracks → Events → Fans → Scene

This structure is much more interesting than starting by thinking about "posts, likes, and followers." The product is built around the real music scene, and not around a generic social network.

### Administrator

In SceneCore, the Administrator has a different role from the other actors: they do not participate in the scene as a band or a fan; they keep the scene organized, trustworthy, and healthy.

Their responsibilities fall into four areas.

1. Managing users

The Administrator can:

View users.
Edit administrative information.
Suspend or reactivate accounts.
Block accounts that violate the rules.
Manage permissions and roles.
View the basic history of administrative actions.
Administrator
│
├── Users
│   ├── View
│   ├── Suspend
│   ├── Reactivate
│   └── Manage roles
2. Moderating the scene

Since SceneCore will likely host content created by the participants themselves, the Administrator can:

Review reports.
Remove inappropriate content.
Moderate band profiles.
Moderate events.
Moderate releases and false information.
Resolve content-related disputes.
Record the reason for a moderation action.

Auditability is the goal:

Report
  ↓
Administrator reviews
  ↓
Decision
  ├── Keep
  ├── Hide
  ├── Remove
  └── Suspend account

3. Managing SceneCore's structure

This is a particularly important role.

The Administrator can manage data that structures the platform:

Genres
Subgenres
Cities
Regions
Tags
Categories
Event statuses
Other system-controlled data

For example:

Genre
├── Punk
│   ├── Crust
│   ├── D-beat
│   └── Hardcore Punk
│
└── Metal
├── Doom
├── Black Metal
└── Death Metal

This prevents each band from inventing its own classification.

4. Managing the system itself

They can also:

View the administrative dashboard.
Check basic metrics.
Manage platform settings.
View administrative logs.
Manage reports.
Track operational issues.
What they shouldn't do

I would avoid giving the Administrator unnecessary powers over user activity.

For example, they shouldn't:

Create Epics on behalf of fans.
Publish releases on behalf of bands unnecessarily.
Arbitrarily alter a band's profile.
Manipulate follower counts.
Interact as if they were a fan.
Have unnecessary access to private data.

The rule could be:

The Administrator manages the system; they do not represent scene participants.

The four actors look like this:
SCENECORE
│
┌────────────────────┼────────────────────┐
│                    │                    │
BAND                 FAN               ORGANIZER
│                    │                    │
publishes            discovers           organizes
music                follows               events
creates profile      participates          promotes
│                    │                    │
└────────────────────┼────────────────────┘
│
┌──────┴──────┐
│             │
ADMINISTRATOR   SCENE
│
organizes/moderates
│
maintains integrity
In terms of the MVP

Initially, I would limit the Administrator to just:

Users

list
view
suspend/reactivate

Moderation

view reports
review content
remove content
log decision

Taxonomy

manage genres
manage locations/categories

Administration

basic dashboard
logs/audit

This is sufficient for SceneCore to start operating without creating a massive back-office system. And, conceptually, the most important thing is that the Administrator is a governance role, whereas the Band, Organizer, and Fan are participants in the scene.

---

## 3. Core User Journeys

Each journey below corresponds to a task in ROADMAP.md §0.3. Journeys already
reachable in the app are noted as such; the rest describe the intended flow
for phases not yet built (Store, Payments, Subscriptions, Events).

### Journey 1 — Discover a Band

*Built (Phase 4).*

1. Visitor accesses the platform.
2. Visitor browses or is directed to a band (e.g., via a shared link or
   Spotify).
3. Visitor opens the band's public page (`GET /:slug`).

### Journey 2 — View a Band's Public Page

*Built (Phase 4).*

1. Visitor opens an approved band's public page.
2. Visitor sees the band's name, description, links, and published albums.
3. Pending, rejected, or suspended bands are not reachable at this URL.

### Journey 3 — Listen to Music

*Built (Phase 5).*

1. Visitor opens a band's public page.
2. Visitor sees the band's published albums as cover-and-title cards.
3. Visitor opens an album on Spotify to listen ("Listen on Spotify").
4. Draft albums are never shown.

Revised 2026-09-16: SceneCore no longer mirrors Spotify's track listing or
embeds a per-track player. An album is a pointer to Spotify, which keeps
the band's streams, counts and distribution exactly where they already
are.

### Journey 4 — Create an Account

*Built (Phase 2).*

1. Visitor registers with an email and password.
2. Visitor is authenticated and becomes a Fan (the base authenticated role;
   see `docs/permissions.md`).

### Journey 5 — Follow a Band

*Built (Phase 6).*

1. Fan opens an approved band's public page.
2. Fan follows the band.
3. The band's follower count updates and the Fan's UI reflects the
   following state.
4. Fan can unfollow at any time.

### Journey 6 — Access Exclusive Content

*Partially built (Phase 7): Public and Follower visibility are built;
Subscriber visibility is not yet reachable (see ROADMAP.md Phase 7 note —
blocked on Phase 10).*

1. Band publishes a post with Public, Followers, or Subscribers visibility.
2. A Visitor can see only Public posts.
3. A Fan who follows the band can additionally see Follower posts.
4. A Fan who subscribes to the band would additionally see Subscriber
   posts, once Phase 10 (Subscriptions) exists to establish that
   relationship.

### Journey 7 — Purchase a Product

*Not built (Phase 8 — Store). Payments (Stripe) is available, but Store
also needs Stripe Connect band onboarding (ADR-007), not yet built.
Describes the intended flow only.*

1. Fan opens a band's store and selects a product (and variant, if
   applicable).
2. Fan adds the product to their cart — at most one active cart at a
   time, scoped to that one band (ADR-003, clarified 2026-09-17).
3. Fan enters a shipping address and checks out via Stripe Connect
   (destination charge, 25% platform commission — ADR-007).
4. Payment is confirmed and an order is created with a price/product
   snapshot.
5. Inventory (per variant/SKU) is decremented consistently with the
   purchase.

### Journey 8 — Subscribe

*Built (Phase 10 — Subscriptions, on top of Phase 9 — Payments/Stripe,
both implemented as of 2026-09-16/17 — see `docs/architecture.md` §5).*

1. Fan selects a band's subscription plan.
2. Fan completes checkout through Stripe Checkout Sessions.
3. Payment is confirmed via webhook.
4. Subscription becomes active.
5. Subscriber-only content becomes available to the Fan (see Journey 6).

### Journey 9 — Purchase an Event Ticket

*Not built (Phase 11 — Events and Tickets). Payments (Stripe) is
available; this phase has not been scoped/implemented yet.*

1. Fan opens a band's published event.
2. Fan selects a ticket batch and quantity.
3. Fan checks out and pays through the approved payment provider.
4. Payment is confirmed and a ticket (with a unique identifier and QR
   code) is issued to the Fan.

### Journey 10 — Validate a Ticket

*Not built (Phase 11 — Events and Tickets). Describes the intended flow
only.*

1. Door staff (a Band Member/Administrator or designated role — not yet
   defined) scans a ticket's QR code at check-in.
2. The system verifies the ticket belongs to the event and has not already
   been used.
3. A valid, unused ticket is marked used and check-in succeeds.
4. An already-used or invalid ticket is rejected, with the reason shown.

---

## 4. MVP Scope

This section distinguishes what is mandatory for the MVP, what is optional
and deferred, and what is explicitly excluded — per ROADMAP.md 0.4. Status
reflects ROADMAP.md as of this writing; a feature listed as mandatory is not
necessarily built yet (see the linked phase for build status).

### 4.1 Mandatory Functionality

The following domains are required for the MVP (each maps to a ROADMAP.md
phase):

**Foundation** (Phase 2)
- Authentication (registration, login, logout, session management)
- User profiles

**Bands** (Phase 3)
- Create/edit band
- Band members and band administrators
- Band approval (pending/approved/rejected by a platform administrator)
- Multi-band isolation (a band cannot access another band's private data)

**Public band pages** (Phase 4)
- Public band page reachable by slug
- Visible only for approved bands

**Music** (Phase 5)
- Releases (albums) and tracks
- Draft/published state, gating public visibility
- Playback via Spotify embed (no self-hosted audio — see
  `docs/architecture.md`)

**Followers** (Phase 6)
- Follow/unfollow a band

**Exclusive content** (Phase 7)
- Posts with Public and Followers visibility (built); Subscriber visibility
  (schema ready; not reachable until Subscriptions exists — see 4.2)
- Media on posts: images, videos, downloads, with file validation and
  storage (not yet built — ROADMAP.md 10.2)

**Store** (Phase 8)
- Products, variants (SKU-level price and stock, per-product min. one
  default variant), inventory, single-active-cart-per-user (one band at
  a time — ADR-003, clarified 2026-09-17), checkout via Stripe Connect
  with a 25% platform commission (ADR-007), shipping address and cost
  captured on the order (`docs/database.md` Products/ProductVariants/
  Carts/Orders)
- Not yet built. No longer blocked on payment provider selection — Stripe
  is already integrated and used for Subscriptions (see Payments below)
  — but Store specifically needs Stripe Connect (band onboarding,
  connected accounts), which is separate infrastructure from the plain
  Checkout Sessions Subscriptions already uses.

**Payments** (Phase 9)
- Stripe is the approved and already-integrated payment provider
  (`docs/architecture.md` §5) — the "not yet named" status below Phase 9
  in earlier drafts of this document is outdated as of 2026-09-17.
- Built and in production use for Subscriptions (Checkout Sessions,
  webhooks, idempotency — see `docs/architecture.md`). Store's use of
  Payments (Stripe Connect, destination charges, per-band onboarding) is
  not yet built — see Store above and ADR-007.

**Subscriptions** (Phase 10)
- Plans, recurring billing, subscriber content access
- Built (`Subscription`, `BandMembershipPrice`, `StripeSubscriptionSwitcher`,
  `StripeCheckoutCompletedHandler`, `StripeSubscriptionUpdatedHandler`,
  `StripeSubscriptionDeletedHandler` — see `docs/architecture.md` §5).

**Events and tickets** (Phase 11)
- Events, ticket batches, QR-coded tickets, check-in/validation
- Not yet built. Payments (Stripe) is available; this phase itself has
  not been scoped/implemented yet.

**Platform administration** (Phase 12)
- Band moderation, administrative audit log, admin panel (bands/users/
  privileges)
- Content moderation (unpublish) implemented; reported-content review is
  deferred (see 4.2 — no reporting/flagging system is defined).

A domain being "mandatory" means it is approved MVP scope, not that it must
be implemented before every other domain — ROADMAP.md 2.1 governs sequencing
and 2.3 requires slicing large phases.

### 4.2 Optional / Deferred Functionality

Recorded as candidates, not authorized for implementation until scoped and
approved (see ROADMAP.md §22 Future Features for the authoritative list):

- Follower notifications (channel, trigger, and UI undefined)
- Fan-facing feed of followed bands' activity (undefined scope)
- Content moderation via user reports (no reporting/flagging system
  defined)
- Advanced band metrics/analytics beyond follower count
- Band member history across bands (e.g., "played in Band A 2022–2024,
  now in Band B")
- Discogs Marketplace integration (proposed 2026-09-17): let a band's vinyl
  and physical-media listings from Discogs Marketplace surface inside its
  SceneCore store, with checkout completing on SceneCore (money flows
  through the band's Store, ADR-007) rather than handing off to Discogs'
  own checkout — that checkout-ownership decision was made 2026-09-17,
  approving the larger of the two integration shapes originally proposed.
  Still blocked, not merely deferred: it depends on Store (Phase 8)
  existing first, including the Stripe Connect band-onboarding flow
  (ADR-007) — Payments (Stripe) itself is no longer the blocker, that part
  was already built for Subscriptions, but Store's Connect-specific
  checkout is not. Once Store is built, this still needs its own scoping
  pass for the Discogs-specific parts: order/inventory sync with Discogs'
  own API, and how a Discogs-sourced listing maps onto
  `docs/database.md`'s Product/ProductVariant model.

### 4.3 Explicitly Excluded Functionality

The following are NOT part of the MVP and must not be implemented without
separate product validation and explicit approval (see ADR-005):

- Scene-based social network or scene graph
- Scene-level discovery by genre and location
- Cross-band community spaces and scene participation
- Algorithmic recommendations (bands, releases, events, or scenes)
- Fan-to-fan messaging or generic social posting (likes, comments, feeds)
- Scene-level feeds, follows, and moderation workflows
- Replacing Spotify as a streaming and discovery platform
- Requiring bands to abandon Bandcamp, Patreon, or other complementary
  channels
- Self-hosted audio/video streaming infrastructure

Claude must not implement these features unless explicitly authorized.

---

## 5. Acceptance Criteria

Per ROADMAP.md 0.5, one set of criteria per mandatory domain from §4.1.
Unresolved requirements each criterion depends on are listed at the end of
this section rather than repeated inline.

### Foundation (Authentication, Profiles)

- A visitor can register with an email and password and is authenticated
  immediately after.
- A user can log in, log out, and have their session end on logout.
- A user can view and edit their own profile; a user cannot edit another
  user's profile.
- Protected resources are unreachable without authentication.

### Bands

- A band can have multiple administrators (`docs/database.md`
  BandMemberships).
- A band administrator can edit only their own band; another band's
  administrator gets a 403/redirect, not a 404 that leaks existence
  differently from a real 404.
- A band can never be left without at least one administrator (existing
  `BandMembership` invariant).
- A band's approval status (pending/approved/rejected/suspended) is set
  only by a platform administrator, never by the band itself.

### Public Band Pages

- Only approved bands are reachable at `GET /:slug`.
- Pending, rejected, and suspended bands return the same not-found response
  a visitor would see for a nonexistent slug (no status leak).
- The public page never exposes draft albums or non-public posts,
  regardless of how the URL is reached.

### Music

Revised 2026-09-16. An album is a link out to Spotify rather than a track
listing SceneCore holds, so the per-track rules below no longer apply.

- An album belongs to exactly one band.
- Draft albums are not publicly accessible under any route.
- Published albums are publicly accessible only through their band's
  public page.
- An album's audio is never hosted by SceneCore: listening happens on
  Spotify, reached from the album's cover card.

Previously: a track belonged to exactly one album; draft tracks were not
publicly accessible; a track could not be published without a valid
Spotify track URL; and publishing or unpublishing an album cascaded to its
tracks.

### Followers

- A fan can follow and unfollow an approved band; an anonymous visitor
  cannot.
- A user cannot follow the same band twice (idempotent follow).
- A user cannot unfollow on another user's behalf.

### Exclusive Content

- A post's visibility (Public/Followers/Subscribers) determines who can see
  it; enforcement happens server-side, not by hiding UI.
- A non-follower cannot see Follower-visibility posts.
- A non-subscriber cannot see Subscriber-visibility posts. Subscriptions
  (Phase 10) is now built, so this gate is reachable — confirm current
  test coverage rather than treating it as still blocked.
- A band administrator can manage only their own band's posts.

### Store (not yet built)

- At most one active cart per user platform-wide, and that cart holds
  products from exactly one band (ADR-003, clarified 2026-09-17).
- A product's price and stock live on its variant (SKU), not the product
  itself — every product has at least one variant.
- Inventory never goes negative; concurrent purchases cannot both consume
  the last unit of a variant.
- An order snapshots product name, variant name, and price at time of
  purchase, independent of later product/variant edits.
- Checkout happens through the band's Stripe Connect account; SceneCore's
  25% commission (ADR-007) is applied via `application_fee_amount` in the
  same transaction, not a separate transfer.
- A band without an active Stripe Connect account cannot open Store
  checkout.

### Payments

- Monetary values are stored as integer cents (`docs/payments.md`).
- Every payment webhook validates authenticity before acting on it.
- Every payment webhook is idempotent under retries and duplicate/
  out-of-order delivery.
- No complete card data or sensitive payment payloads are logged or stored.
- Payment state transitions follow `docs/payments.md`'s defined states;
  the payment provider (Stripe) is the source of truth for payment status.
- Built and verified for Subscriptions. Store's Stripe Connect flow is not
  yet built — its webhooks must additionally distinguish connected-account
  events from platform-account events (ADR-007).

### Subscriptions

- A subscription's active/cancelled/past-due/expired state stays
  synchronized with Stripe's webhooks.
- Subscriber-only content access is granted only while the underlying
  subscription is active, per the approved grace-period rule (see
  Unresolved Requirements).
- Cancelling a subscription does not retroactively delete content already
  consumed, only future access.
- Built (`Subscription`, `StripeSubscriptionUpdatedHandler`,
  `StripeSubscriptionDeletedHandler`) — confirm current test coverage
  against this list rather than treating these as unimplemented.

### Events and Tickets (not yet built)

- A ticket has a unique identifier and is associated with exactly one
  event and one purchaser.
- A used ticket cannot be validated (checked in) a second time.
- Ticket data is not guessable/enumerable from its public identifier.

### Platform Administration

- A platform administrator action (approve/reject/suspend/reactivate/
  unpublish) is recorded in the audit log with actor, timestamp, and
  affected resource.
- A platform administrator cannot edit a band's content as if they were a
  band member (e.g., cannot edit a band's profile fields, only its
  moderation status).
- The `/admin` namespace 404s for non-platform-admins (existing pattern,
  not a 403).

### Unresolved Requirements

The following acceptance criteria above depend on product decisions not
yet made, tracked in §7 Open Questions:

- Store/Events checkout flow for unauthenticated visitors (§7: can a cart
  be started before account creation?).
- Subscription cancellation/failed-payment grace-period rule (referenced
  in ROADMAP.md Phase 10 but not yet defined).
- Store refund behavior — does refunding also reverse SceneCore's
  application fee, and who initiates it, the band or SceneCore
  (`docs/payments.md` Financial Rules)?
- Shipping cost calculation method for Store orders (flat rate, zone/
  weight-based, or a carrier-rate API — `docs/database.md`
  ShippingAddresses).
- Door/check-in role for ticket validation (ROADMAP.md 11.5 assumes
  someone validates tickets, but that role isn't in `docs/permissions.md`
  yet — likely a Band Member/Administrator action, to be confirmed).

---

## 6. Product Rules

- One purchase belongs to one band in the MVP.
- [Other business rules]

---

## 7. Open Questions

- Can a visitor start a product or ticket purchase without an account and
  create one during checkout?
- After the band-home proposition is validated, should SceneCore formally expand
  toward scene-level discovery and community?
- What is the subscription cancellation/failed-payment grace-period rule
  (referenced by ROADMAP.md Phase 10 but not yet defined)?
- Who is authorized to validate (check in) an event ticket — a Band
  Member/Administrator of the hosting band, or a separate door-staff role
  not yet in `docs/permissions.md`?
