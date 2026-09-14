# Product Specification

## 1. Product

### Name

SceneCore

### Description

A multi-band platform for music, exclusive content, subscriptions, merchandise, and tickets.

### Problem

SceneCore primarily solves a problem of centralization and relationship between bands, fans, and musical content, bringing together on a single platform what is normally scattered across different services.

### Solution

The service solves the problem by transforming fragmentation into a unique and integrated experience.

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

SceneCore centralizes the relationship between independent bands and their fans, bringing together music, content, community, and monetization in a single experience.

Or, thinking more as a service proposition:

SceneCore is the place where a band not only publishes its music, but builds and monetizes its direct relationship with its followers.

And this helps to make it clearer what is being sold: it's not just software for bands. It's an infrastructure to transform fan attention into relationships and relationships into financial support, all within a single platform.

Important: this last differentiation is a strategic interpretation based on the MVP. The document does not yet establish that this is a proven competitive advantage against Bandcamp, Patreon, Spotify, etc.; This should become an explicit product decision.

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

No SceneCore, o Administrator deve ter uma função diferente dos demais atores: ele não participa da cena como banda ou fã; ele mantém a cena organizada, confiável e saudável.

Eu separaria suas responsabilidades em quatro áreas.

1. Administrar usuários

O Administrator pode:

Visualizar usuários.
Editar informações administrativas.
Suspender ou reativar contas.
Bloquear contas que violem regras.
Gerenciar permissões e papéis.
Ver o histórico básico de ações administrativas.
Administrator
│
├── Users
│   ├── View
│   ├── Suspend
│   ├── Reactivate
│   └── Manage roles
2. Moderar a cena

Como o SceneCore provavelmente terá conteúdo criado pelos próprios participantes, o Administrator pode:

Revisar denúncias.
Remover conteúdo inadequado.
Moderar perfis de bandas.
Moderar eventos.
Moderar lançamentos e informações falsas.
Resolver conflitos relacionados a conteúdo.
Registrar o motivo de uma ação de moderação.

O ideal é ter auditabilidade:

Report
  ↓
Administrator reviews
  ↓
Decision
  ├── Keep
  ├── Hide
  ├── Remove
  └── Suspend account

3. Administrar a estrutura do SceneCore

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

### Journey 1 — Discover a Band

1. Visitor accesses the platform.
2. Visitor discovers a band.
3. Visitor opens the band's page.
4. Visitor listens to music.

### Journey 2 — Become a Fan

1. Visitor creates an account.
2. User follows a band.
3. User receives access to follower content.

### Journey 3 — Subscribe

1. Fan selects a subscription.
2. Fan completes checkout.
3. Payment is confirmed.
4. Subscription becomes active.
5. Exclusive content becomes available.

---

## 4. MVP Features

### Foundation

- Authentication
- User profiles

### Bands

- Create band
- Edit band
- Band members
- Band administrators

### Music

- Releases
- Tracks
- Audio player
- Draft/published tracks

### Exclusive Content

- Posts
- Images
- Videos
- Downloads
- Visibility rules

### Store

- Products
- Variants
- Inventory
- Cart
- Checkout
- Orders

### Subscriptions

- Plans
- Recurring payments
- Subscription lifecycle

### Events

- Events
- Tickets
- QR codes
- Check-in

---

## 5. Out of Scope

The following are NOT part of the MVP:

- [feature]
- [feature]
- [feature]

Claude must not implement these features
unless explicitly authorized.

---

## 6. Acceptance Criteria

### Bands

- A band can have multiple administrators.
- A band administrator can edit only their own band.
- Users cannot access another band's private data.

### Music

- Draft tracks are not publicly accessible.
- Published tracks are publicly accessible.

### Payments

- Payment events are idempotent.
- Payment state is persisted.

---

## 7. Product Rules

- One purchase belongs to one band in the MVP.
- [Other business rules]

---

## 8. Open Questions

- [Question requiring decision]
- [Question requiring decision]