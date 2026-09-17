# Membership, Band Admin & Administration

## Objective

Implement a membership system in SceneCore for independent bands, made up of three plans:

- Fan
- Supporter
- Core Member

The system must also have two distinct administrative levels:

1. **Band Admin** — administration of a specific band.
2. **SceneCore Administrator** — platform-wide administration.

The implementation must preserve a clear separation between:

- what the fan can access;
- what the band can offer;
- what the platform administrator can administer.

Do not create three separate admin panels for the three plans.

There must be **a single Band Admin**, with features tied to the resources available to that band.

---

# 1. Fundamental rules

Before writing code:

1. Inspect the application's current structure.
2. Identify how users, bands, authentication, payments, and content are currently implemented.
3. Check the existing models before creating new ones.
4. Reuse existing structures where it makes sense.
5. Do not create premature abstractions.
6. Do not introduce features that are not specified in this document.
7. Do not implement duplicated logic for each plan.
8. Use access rules based on membership/benefits.
9. Keep business logic out of the controllers.
10. Prefer simple models, policies, and services.
11. Do not change existing features without need.
12. Before implementing a structural change, explain the impact and verify that it is compatible with the existing architecture.

---

# 2. Product hierarchy

The conceptual architecture must be:

```text
SceneCore
│
├── Fans
│   ├── Fan
│   ├── Supporter
│   └── Core Member
│
├── Bands
│   └── Band Admin
│
└── SceneCore Administration
    └── SceneCore Administrator
```

Memberships belong to the relationship between a user and a band.

A user can hold different memberships in different bands.

Example:

```text
User
 ├── Band A → Fan
 ├── Band B → Supporter
 └── Band C → Core Member
```

Do not assume the plan is a global property of the user.

---

# 3. Membership Plans

The three initial plans are:

## Fan

Price:

```text
US$ 3
```

A dollar representation must also exist wherever the interface or configuration requires conversion.

Benefits:

- Exclusive band feed
- News ahead of the general public
- Behind-the-scenes photos and short videos
- Some demos and alternative versions
- Polls about setlists, cover art, or merchandising
- Fan badge on the profile
- Access to the subscriber community

Promise:

> Get closer to the band.

---

## Supporter

Price:

```text
US$ 5
```

Benefits:

- All Fan benefits
- Early releases
- Full demos and rehearsal recordings
- Songwriting and production journal
- Exclusive videos and streams
- Name in the digital credits as a supporter
- Discount on merchandising and tickets
- Early access to sales

Promise:

> Support the music and follow how it is made.

---

## Core Member

Price:

```text
US$ 8
```

Benefits:

- All Supporter benefits
- Periodic private livestreams
- Q&A sessions
- Rare content: archives, old recordings, and unreleased versions
- Priority on tickets and limited products
- Larger discounts
- Name on a permanent supporters page
- Credits in liner notes or selected releases
- Giveaways of signed items
- Direct messaging to the band
- The ability to vote on decisions the band has chosen in advance
- Access to special virtual or in-person meetups

Promise:

> Be part of the band's core.

---

# 4. Plan progression

The conceptual progression is:

```text
Fan
  ↓
follows

Supporter
  ↓
sustains and takes part

Core Member
  ↓
belongs to the core
```

This progression must show up in the user experience.

However, do not duplicate features across plans.

A Core Member must inherit the benefits of the lower levels through the benefits hierarchy.

Avoid implementations such as:

```ruby
if fan?
elsif supporter?
elsif core_member?
```

scattered across the application.

Prefer a centralized benefits/permissions rule.

---

# 5. Benefits

Create a structure that can represent membership benefits.

Conceptual example:

```text
Fan
├── exclusive_feed
├── early_news
├── behind_the_scenes
├── alternative_versions
└── subscriber_community

Supporter
├── early_releases
├── complete_demos
├── production_journal
├── exclusive_live
├── digital_credits
├── merch_discount
└── early_sales

Core Member
├── private_lives
├── q_and_a
├── rare_archives
├── priority_tickets
├── higher_discount
├── permanent_credits
├── signed_item_giveaways
├── direct_messages
├── community_votes
└── special_meetings
```

Benefits from lower levels must be inherited.

Example:

```text
Core Member
    ↓
Supporter benefits
    ↓
Fan benefits
```

Do not duplicate records unnecessarily.

---

# 6. Band Admin

Do not create a different admin panel for each membership.

Create:

```text
Band Admin
```

The band administers its own community, content, memberships, and benefits.

A band must never be able to administer another band's data.

---

# 7. Band Admin Navigation

The conceptual navigation must be:

```text
Dashboard

Band
├── Profile
├── Members
└── Settings

Content
├── Posts
├── Photos
├── Videos
├── Audio
├── Archives
└── Drafts

Releases
├── Releases
├── Early Access
└── Credits

Community
├── Feed
├── Discussions
├── Polls
└── Moderation

Members
├── All Members
├── Fans
├── Supporters
└── Core Members

Engagement
├── Messages
├── Q&A
├── Sessions
└── Votes

Commerce
├── Merch
├── Tickets
├── Discounts
└── Early Access

Membership
├── Plans
├── Benefits
├── Subscriptions
└── Credits

Analytics
├── Members
├── Revenue
├── Engagement
└── Content

Settings
```

Do not implement every screen automatically if it is not yet required for the MVP.

Check the ROADMAP and the project's current state first.

---

# 8. Band Admin — Dashboard

The Dashboard must let the band quickly understand its community.

Possible information:

- number of Fans;
- number of Supporters;
- number of Core Members;
- recurring revenue;
- new members;
- recent activity;
- views;
- comments;
- poll participation.

Conceptual example:

```text
1,248 Fans
184 Supporters
37 Core Members

R$ 12.480 / month

+42 members this month
```

Do not invent additional metrics without need.

---

# 9. Content Management

The band must be able to create content.

Initial types:

- text;
- photo;
- video;
- audio;
- poll.

Every piece of content must have a visibility policy.

Example:

```text
Visibility:

Public
Fan
Supporter
Core Member
```

Access must be determined by the user's membership in that band.

---

# 10. Exclusive Feed

Band Admin must let the band publish exclusive content.

Example:

```text
New Post

Title:
Behind the new record

Content:
...

Visibility:
Fan
```

Or:

```text
Visibility:
Supporter
```

Or:

```text
Visibility:
Core Member
```

The band must be able to control the content's audience.

---

# 11. Polls

The band must be able to create polls.

Example:

```text
Question:

Which song should we play live?

Options:

Song A
Song B
Song C

Audience:

Core Members
```

The band must be able to define:

- audience;
- options;
- duration;
- when the results appear.

Core Member votes are **decisions the band has chosen in advance**.

Do not implement a system in which Core Members can vote arbitrarily on any aspect of the band.

The band decides which decisions can be put to a vote.

---

# 12. Releases

Supporters and Core Members can receive releases early.

The system must support access windows.

Example:

```text
Core Member
October 10

Supporter
October 15

Public
October 20
```

The implementation must avoid duplicating the file or the content.

Prefer a single release with availability rules.

---

# 13. Composition Journal

Supporters and Core Members can be given access to the creative process.

The band must be able to create:

```text
Composition Journal Entry

Title:
How this song was created

Content:
...

Attachments:
demo.wav
guitar.mp3
lyrics.pdf

Visibility:
Supporter
```

Do not build a complex CMS without need.

---

# 14. Exclusive Lives

Supporters can have access to exclusive livestreams.

Core Members can also join private livestreams.

The band must be able to:

- create a stream;
- set the date;
- set the time;
- set the audience;
- publish a description;
- control the replay where applicable.

Example:

```text
Listening Session

Date:
October 20, 2026

Audience:
Supporter + Core Member
```

---

# 15. Core Sessions

Core Members have access to special meetups.

Possible types:

```text
Video
Audio
Q&A
Listening Party
Meet & Greet
```

The band can define:

- date;
- time;
- type;
- participants;
- seat limit;
- description.

Example:

```text
Private Listening Session

20 seats

18 confirmed
2 available
```

Do not implement a full events/tickets system if that is not part of the current scope.

---

# 16. Direct Messages

Core Members can message the band directly.

Band Admin must have an inbox.

Example:

```text
Messages

Carlos
"When are you planning to release..."

Ana
"I have a suggestion..."

Pedro
"I'd like to ask..."
```

The band must be able to:

- view;
- reply;
- archive;
- block;
- moderate.

Important:

The benefit means a Core Member can send a message directly to the band.

It does not mean the band is required to reply immediately or individually.

Consider rate limits and anti-abuse mechanisms before implementing.

Do not build a complex chat system without need.

---

# 17. Credits

Supporters can appear in digital credits.

Core Members can also appear in:

- the permanent supporters page;
- liner notes;
- selected releases.

The system must let the band control where the names appear.

Do not assume every release must necessarily list every member.

---

# 18. Merchandising

Supporters get a discount.

Core Members get a larger discount.

Band Admin must allow discount rules to be configured.

Example:

```text
Fan
0%

Supporter
10%

Core Member
20%
```

The values must be configurable.

Do not hardcode percentages if the current architecture allows configuration.

---

# 19. Early Access

The band must be able to configure early access.

Example:

```text
Limited Vinyl

Core Member
24 hours early

Supporter
12 hours early

Fan
Public release
```

Early access must be handled as a membership rule, not as separate copies of the product.

---

# 20. Tickets

Once a ticketing integration exists, Supporters can receive early access and Core Members can receive priority.

Do not implement a full ticketing system just to satisfy this rule if one does not already exist.

Build the integration when the corresponding infrastructure is in place.

---

# 21. Core Member Giveaways

Core Members can enter giveaways for signed items.

The feature must be treated as an exclusive benefit.

Before implementing real giveaways, check:

- legal requirements;
- platform rules;
- whether an integration is needed;
- eligibility rules.

Do not invent legal rules.

---

# 22. Band Members

The band must have a view of its members.

Categories:

```text
All
Fan
Supporter
Core Member
```

Relevant information:

- user;
- membership;
- status;
- join date;
- benefits;
- activity where available.

The band must not have access to unnecessary personal data.

Apply the principle of least privilege.

---

# 23. SceneCore Administrator

The Administrator is different from Band Admin.

The Administrator operates the entire platform.

Conceptually:

```text
SceneCore Administrator

├── Bands
├── Users
├── Memberships
├── Payments
├── Content
├── Reports
├── Moderation
├── Analytics
├── Platform Settings
└── Audit
```

The Administrator can administer platform-wide resources.

---

# 24. Administrator — Bands

The Administrator must be able to:

- view bands;
- view status;
- administer accounts when authorized;
- suspend accounts when necessary;
- look up operational information.

The Administrator must not take on the role of a band member.

---

# 25. Administrator — Users

The Administrator can:

- find users;
- view status;
- look up memberships;
- handle reports;
- apply administrative actions when necessary.

Do not expose personal data beyond what is necessary.

---

# 26. Administrator — Payments

The Administrator must have an operational view of:

- memberships;
- payments;
- subscriptions;
- cancellations;
- refunds;
- transaction status.

Do not store sensitive card data directly.

Use the payment gateway defined by the project.

If an integration already exists, reuse it.

---

# 27. Administrator — Moderation

The Administrator must have tools for:

- reports;
- reported content;
- reported users;
- reported bands;
- moderation actions;
- action history.

This moderation must be separate from the day-to-day moderation the band performs.

---

# 28. Permissions

Authorization must respect three levels:

```text
User
 ↓
Membership
 ↓
Band Admin
 ↓
SceneCore Administrator
```

Exemplo:

```text
Fan
→ can access Fan content

Supporter
→ can access Fan + Supporter content

Core Member
→ can access Fan + Supporter + Core content

Band Admin
→ administers its own band

SceneCore Administrator
→ administers the platform
```

Never let a user's membership grant administrative privileges.

Membership and role are different concepts.

---

# 29. Membership ≠ Role

Do not conflate:

```text
Fan
Supporter
Core Member
```

with:

```text
Band Admin
SceneCore Administrator
```

Membership represents:

> the user's relationship with a band.

Role represents:

> administrative authority in the system.

Example:

```text
User A
membership: Core Member
role: user

User B
membership: Supporter
role: band_admin

User C
membership: Fan
role: platform_admin
```

Roles must be evaluated separately.

---

# 30. Multi-band

The system must account for a person following several bands.

Therefore:

```text
User
  │
  ├── Membership → Band A → Fan
  ├── Membership → Band B → Supporter
  └── Membership → Band C → Core
```

Do not create:

```text
user.membership_plan
```

as a global rule, if doing so prevents independent per-band memberships.

Membership must belong to the band's context.

---

# 31. Security

Every administrative action must validate:

```text
current_user
+
role
+
band ownership / association
```

Exemplo:

```text
Band Admin A
```

cannot edit:

```text
Band B
```

even if it knows the band's ID.

Never trust parameters sent by the browser alone.

---

# 32. Controllers

Controllers must stay thin.

Do not put rules such as:

```ruby
if current_user.core_member?
```

scattered across the controllers.

Prefer:

- policies;
- models;
- scopes;
- services when a flow is genuinely complex.

Conceptual example:

```ruby
MembershipPolicy
ContentPolicy
BandPolicy
```

The concrete implementation must follow the patterns already present in the project.

---

# 33. Models

Before creating new models, review the existing ones.

Possible conceptual structure:

```text
User
Band
Membership
MembershipPlan
Benefit
Content
Poll
Vote
Release
Credit
Subscription
```

This list is conceptual.

**Do not create all of these models automatically.**

Determine which are actually necessary after reviewing the existing code and the MVP.

---

# 34. Subscription

The financial subscription must be separated from the membership concept where necessary.

Conceptually:

```text
User
   ↓
Subscription
   ↓
Membership
   ↓
Band
```

The concrete implementation must respect the payment gateway the project uses.

Possible statuses must be defined based on the existing gateway.

Do not invent financial states.

---

# 35. Content Access

Content access must be derived from the membership.

Example:

```text
content.required_plan = supporter
```

Then:

```text
Fan
→ deny

Supporter
→ allow

Core Member
→ allow
```

For Core content:

```text
Fan
→ deny

Supporter
→ deny

Core Member
→ allow
```

For public content:

```text
any user
→ allow
```

---

# 36. Access hierarchy

The conceptual rule is:

```text
Public
   ↓
Fan
   ↓
Supporter
   ↓
Core Member
```

Where:

```text
Core Member >= Supporter >= Fan
```

Do not implement independent rules for each resource if a hierarchy solves the problem.

---

# 37. UX

The interface must clearly communicate:

```text
Fan
Get closer to the band.

Supporter
Support the music and follow how it is made.

Core Member
Be part of the band's core.
```

When a user hits locked content, explain which membership is required.

Example:

```text
This content is available to Supporters and Core Members.

Upgrade to Supporter
```

Do not silently hide the existence of the content.

---

# 38. Upgrade

The user must be able to understand the progression:

```text
Fan
R$ 10
     ↓
Supporter
R$ 25
     ↓
Core Member
R$ 50
```

On upgrade, the user must automatically receive the benefits matching the new membership.

Avoid duplicating incompatible memberships.

The exact upgrade/downgrade rule must respect the existing payment system.

---

# 39. Downgrade / Cancellation

A subscription can be:

```text
Active
Canceled
Expired
Pending
```

Only use states the payment system actually supports.

When a subscription stops entitling the user to the membership, access to the benefits must be updated to match the subscription's effective state.

Do not grant permanent access based on payment history alone.

---

# 40. Analytics

Band Admin may later track:

```text
Memberships
Revenue
Engagement
Content
```

Examples:

- member growth;
- distribution by plan;
- revenue;
- views;
- participation;
- activity.

Do not build a complex analytics system up front.

Implement only the metrics the MVP requires.

---

# 41. MVP

Prioritize the implementation in this order:

## Phase 1 — Membership foundation

- Membership plans
- Membership per band
- Membership status
- Access hierarchy
- Benefits
- Authorization

## Phase 2 — Band Admin

- Band dashboard
- Member list
- Membership management
- Basic content management

## Phase 3 — Exclusive Content

- Fan content
- Supporter content
- Core content
- Access control

## Phase 4 — Community

- Feed
- Comments
- Polls
- Moderation

## Phase 5 — Supporter Features

- Early releases
- Demos
- Composition journal
- Exclusive content
- Credits

## Phase 6 — Core Features

- Private sessions
- Q&A
- Direct messages
- Core votes
- Special meetings
- Permanent credits

## Phase 7 — Commerce

- Merch discounts
- Ticket benefits
- Early sales
- Priority access

## Phase 8 — Platform Administration

- Users
- Bands
- Memberships
- Payments
- Reports
- Moderation
- Platform analytics

---

# 42. Implementation Strategy

For each phase:

1. Review the existing code.
2. Identify related models.
3. Identify controllers.
4. Identify policies.
5. Identify routes.
6. Identify existing tests.
7. Propose changes.
8. Wait for confirmation whenever there is a relevant architectural change.
9. Implement in small steps.
10. Run the tests.
11. Run the existing lint/formatters.
12. Check for regressions.
13. Update the documentation.
14. Only then move on to the next phase.

Do not implement every phase in a single change.

---

# 43. Test Strategy

Every important rule must have tests.

Test primarily:

### Membership

```text
Fan
Supporter
Core Member
```

### Access

```text
Public content
Fan content
Supporter content
Core content
```

### Authorization

```text
Regular User
Band Admin
SceneCore Administrator
```

### Multi-band

Verify that:

```text
User → Band A → Fan
```

does not grant access to:

```text
Band B → Supporter content
```

### Security

Verify that a Band Admin cannot administer another band.

### Payments

Test membership transitions against the existing payment integration.

Use Minitest if that is the framework the project has already adopted.

---

# 44. Do not

Claude must not:

- create three admin dashboards;
- turn Fan/Supporter/Core into administrative roles;
- let Core Members administer the band;
- let fans vote on decisions the band has not configured;
- create unspecified features;
- build a complex chat without need;
- build a complex CMS;
- build a ticketing system without need;
- build advanced analytics before they are needed;
- duplicate content for each plan;
- scatter membership checks across the controllers;
- store card data;
- assume membership is global to the user;
- grant administrative access based on the plan;
- create abstractions before real duplication exists.

---

# 45. Core architectural principle

SceneCore must maintain this separation:

```text
                ┌─────────────────────┐
                │       USER          │
                └──────────┬──────────┘
                           │
                           ▼
                ┌─────────────────────┐
                │     MEMBERSHIP      │
                │                     │
                │ Fan                 │
                │ Supporter           │
                │ Core Member         │
                └──────────┬──────────┘
                           │
                           ▼
                ┌─────────────────────┐
                │      BENEFITS       │
                └──────────┬──────────┘
                           │
                           ▼
                ┌─────────────────────┐
                │      CONTENT        │
                │      COMMUNITY      │
                │      COMMERCE       │
                └─────────────────────┘


                ┌─────────────────────┐
                │      BAND ADMIN     │
                └──────────┬──────────┘
                           │
                           ▼
                administers ONE band


                ┌─────────────────────┐
                │ SCENECORE ADMIN     │
                └──────────┬──────────┘
                           │
                           ▼
                administers THE PLATFORM
```

The fundamental rule is:

> **Membership determines access and benefits. Role determines administrative authority.**

This separation must be preserved across models, policies, controllers, views, services, routes, and tests.