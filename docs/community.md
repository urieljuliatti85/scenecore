# SceneCore Community

## 1. Purpose

The SceneCore Community is the space where a band maintains an ongoing relationship with its fans and members.

The community exists to make the relationship between a band and its audience deeper than simply:

```text
listen → follow → leave
```

Instead:

```text
discover
   ↓
follow
   ↓
support
   ↓
participate
   ↓
belong
```

The community is therefore a band-centered experience.

It is not intended to become a generic social network.

---

# 2. Core Principle

SceneCore is primarily about the relationship between:

```text
Band ↔ Fan
```

The community should strengthen this relationship.

It should not require SceneCore to become:

- Facebook;
- Instagram;
- Discord;
- Reddit;
- a generic messaging platform;
- a general-purpose social network.

The band's community exists around the band's music, creative process, releases, events and relationship with its supporters.

---

# 3. Community Ownership

Every community belongs to a specific band.

Conceptually:

```text
Band A
  └── Community

Band B
  └── Community
```

There is no global community in the MVP.

A fan participates in communities based on their relationship with individual bands.

---

# 4. Membership Access

Community access may depend on membership level.

Conceptually:

```text
Public
Fan
Supporter
Core Member
```

A band may decide that a particular community space requires:

- no membership;
- Fan membership;
- Supporter membership;
- Core membership.

The access requirement must be enforced server-side.

Membership rules are defined in:

```text
docs/memberships.md
```

Community should consume those rules rather than duplicate them.

---

# 5. Community Spaces

A community may contain different types of spaces.

Examples:

### Band Updates

Band announcements and news.

### Behind the Scenes

Photos and material from the band's activities. Short videos are in development.

### Creative Process

Composition, rehearsal and production material.

### Release Discussion

A space associated with a release.

### Core Sessions

Private experiences for Core Members.

### Q&A

Questions and answers between fans and the band.

### Polls

Questions created by the band where members can participate.

The exact spaces implemented in the MVP must follow the roadmap.

Do not create a generic channel system merely to support these examples.

---

# 6. Band-Centered Interaction

The fundamental interaction is:

```text
Band → Community → Fan
```

The band creates:

- updates;
- exclusive content;
- questions;
- polls;
- events;
- special experiences.

Fans consume and, where explicitly supported, participate.

This preserves SceneCore's music-first positioning.

---

# 7. Fan Participation

Fan participation can include:

- viewing exclusive content;
- participating in polls;
- submitting questions;
- participating in Q&A sessions;
- attending private streams;
- participating in Core Member experiences;
- receiving band communications.

Participation rights depend on the user's membership level and the specific feature.

---

# 8. Fan-to-Fan Social Features

Generic fan-to-fan social functionality is not part of the initial community definition.

Examples requiring separate product approval:

- unrestricted fan-to-fan messaging;
- public social feeds;
- generic likes;
- unrestricted comments;
- fan-created posts;
- groups created by fans;
- cross-band social communities.

These features change the product from a band/fan relationship platform into a social network.

They therefore require explicit product validation before implementation.

The current product scope already treats generic fan-to-fan social posting and messaging as excluded pending separate validation.

---

# 9. Band-to-Fan Communication

Communication between the band and its members is different from fan-to-fan social networking.

The band may communicate through approved product mechanisms such as:

- exclusive posts;
- announcements;
- Q&A;
- private sessions;
- direct messages where explicitly supported;
- notifications.

These mechanisms should remain tied to the band.

---

# 10. Comments

Comments are a separate product decision.

If comments are implemented, they should not automatically turn every post into a public social feed.

Possible rules include:

- only followers can comment;
- membership may be required for certain content;
- comments belong to the band's post;
- the band can moderate comments on its own content;
- platform administrators can intervene when necessary.

The current roadmap contains a proposed comment model with follower-only commenting and band moderation, but explicitly records that this proposal requires product approval before being promoted to authorized scope.

Therefore:

> `community.md` must describe the boundary, not silently authorize comments.

---

# 11. Moderation

Community moderation operates at two levels.

## Band moderation

A band may moderate interactions occurring within its own community.

Examples:

- hide inappropriate content;
- manage questions;
- manage community participation;
- restrict participation where explicitly supported.

Band moderation must be scoped to the band's own resources.

A Band Administrator cannot moderate another band's community.

---

## Platform moderation

A SceneCore Administrator handles platform-level moderation.

Platform moderation exists for cases such as:

- abuse;
- illegal content;
- serious policy violations;
- disputes requiring platform intervention;
- reports involving platform rules.

Platform moderation must be auditable.

The existing platform administration architecture already uses `AdminActionLog` for administrative actions and moderation.

---

# 12. Community and Membership Tiers

Membership levels define progressively deeper access.

```text
Fan
│
├── exclusive content
├── band updates
├── polls
└── community access

Supporter
│
├── everything above
├── early releases
├── complete demos
├── creative process
└── supporter experiences

Core Member
│
├── everything above
├── private sessions
├── Q&A
├── rare archives
├── direct interaction
└── special experiences
```

Community should not implement these benefits independently.

It should ask the Membership domain whether the user has the required entitlement.

---

# 13. Core Member Community

The Core Member community represents the closest digital relationship between a band and its supporters.

It may include:

- private discussions with the band;
- private Q&A;
- unreleased material;
- special announcements;
- private streams;
- voting on decisions selected by the band;
- special meetings.

Core membership does not provide administrative access.

A Core Member remains a fan/member, not a band administrator.

---

# 14. Polls

Polls may be used by bands to involve members in selected decisions.

Examples:

- setlist choices;
- cover songs;
- merchandise preferences;
- release-related questions.

A poll must define:

- the band that owns it;
- the required membership level, when applicable;
- opening time;
- closing time;
- available choices;
- whether multiple answers are allowed;
- whether the user can change their vote.

The system must not imply that every band decision is binding.

A poll represents participation, not transfer of band authority.

---

# 15. Q&A

Q&A sessions allow fans to submit questions to the band.

Access may depend on membership level.

Example:

```text
Fan
  → submit questions to public/community Q&A

Supporter
  → access exclusive Q&A

Core Member
  → access private Q&A
```

The exact availability must be configured according to approved product scope.

Do not introduce a generic question-and-answer engine unless the implementation requires it.

---

# 16. Notifications

Community activities may eventually generate notifications.

Potential sources include:

- new band post;
- new exclusive content;
- poll;
- Q&A;
- subscription event;
- ticket event;
- band message.

Notifications are cross-cutting infrastructure and should not be designed exclusively around community.

The current roadmap already identifies the need for a global notification mechanism and band inbox, while leaving the complete trigger/channel/read-state specification open.

---

# 17. Community Boundaries

Community must remain:

```text
Band-centric
Music-centric
Membership-aware
Moderated
Purposeful
```

It must not become:

```text
Generic social network
Cross-band forum
Generic chat platform
Fan marketplace
Unmoderated public square
```

unless those directions are separately approved.

---

# 18. Authorization

Every community resource must be scoped to its band.

Authorization must verify:

1. authenticated user;
2. target band;
3. relationship with that band;
4. membership level when required;
5. administrative role when required.

Never authorize community actions based solely on:

```ruby
current_user.band_admin?
```

because administration is band-specific.

The correct question is:

```text
Is this user authorized for THIS band?
```

---

# 19. Data Ownership

Community content belongs to the band context in which it was created.

Conceptually:

```text
Community
  belongs_to Band

CommunityContent
  belongs_to Community
```

The exact models should only be introduced when the actual feature requires them.

Do not create speculative abstractions for future community features.

---

# 20. Testing

Community authorization must cover:

### Band isolation

- Band A cannot access Band B community administration.
- Band A administrator cannot modify Band B community resources.

### Membership

- Non-member cannot access member-only community space.
- Fan cannot access Supporter-only space.
- Supporter cannot access Core-only space.
- Core Member can access all inherited community spaces.

### Administrative separation

- Core Member cannot administer community merely because they are Core.
- Band Administrator can administer their own band's community when authorized.
- Band Administrator cannot administer another band's community.

### Moderation

- Band can moderate its own community.
- Band cannot moderate another band's community.
- Platform Administrator can perform platform-level moderation according to policy.

---

# 21. Out of Scope

Unless separately approved:

- global community;
- cross-band community;
- unrestricted fan-to-fan messaging;
- generic social feed;
- fan-created groups;
- generic likes;
- generic social profiles;
- community marketplace;
- Discord-like channels;
- real-time chat;
- community reputation systems;
- karma;
- follower counts as social ranking;
- algorithmic social feeds.

These should not be introduced simply because the underlying architecture could support them.

---

# 22. Product Principle

The SceneCore community exists to answer one question:

> **How can a fan get closer to a band?**

It should strengthen:

```text
music
+
relationship
+
participation
+
support
+
belonging
```

without requiring SceneCore to become a general-purpose social network.
