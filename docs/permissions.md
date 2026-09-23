# Permissions

## Roles

### Visitor

Can:

- view public bands
- listen to public music

Cannot:

- manage bands
- access private content
- manage products

---

### Fan

Can:

- everything Visitor can
- follow bands
- access follower content
- purchase products
- subscribe

---

### Band Member

Can:

- everything Fan can
- view their band's private/draft data
- manage their band's content (music, posts, etc., as those areas are
  implemented)
- validate QR-coded tickets for their own band's events

Cannot:

- invite, remove, or change the role of other band members
- approve/reject their own band
- manage another band's resources

A user may hold membership (as Band Member or Band Administrator) in
more than one band at once — each membership's role only grants
permissions scoped to that specific band.

---

### Band Administrator

A Band Member with elevated permissions within their own band. Can:

- everything Band Member can
- manage their own band's profile
- manage band's products
- manage band's shipping destinations and rates (which also decides the
  countries the band's Store sells to at all)
- issue full refunds for their own band's paid Store orders
- manage band's events
- manage ticket batches for the band's events
- validate QR-coded tickets for the band's events
- invite, remove, and change the role of their band's members

Cannot:

- manage another band's resources
- approve/reject their own band (only a Platform Administrator can)
- access platform administration

---

### Platform Administrator

Can:

- approve, reject, suspend, reactivate, and feature/unfeature any band
- read any band's profile, content, and orders (for support and disputes)
- unpublish an album or a post, delete a post or a comment, and block a
  direct message thread on any band, as platform moderation
- resolve or dismiss a report
- manage platform-level resources: users, categories, platform-wide
  Membership moderation (`/admin/memberships`), audit logs, analytics,
  financial status, band admin requests
- grant themselves (or anyone) an administrator `BandMembership` on any
  band, from `/admin/bands/:id/privileges`

Cannot, merely because of the platform role — these require an
administrator `BandMembership` in that specific band, the same as a Band
Administrator:

- create, edit, or publish a band's albums, posts, events, polls, Core
  Sessions, or album credits
- edit a band's own profile
- manage a band's products, product variants, or shipping zones/rates
- invite, remove, or change the role of a band's team, or manage its fan
  memberships from the band's own panel (`/bands/:id/supporters` —
  `/admin/memberships` is the audited platform-wide path for that)
- reply in, or unblock, a band's direct message threads (reading a thread
  and blocking it, for moderation, are the exceptions above)
- advance a Store order's fulfilment
- reach a band's payment settings or its Stripe account (the Payments tab,
  the Stripe Express dashboard link, or Stripe Connect onboarding). That is
  the band's own money: as with refunds, the platform does not act as the
  band's merchant (see the refunds ADR in `docs/decisions.md`)
- validate an event ticket. Ticket check-in is an operational action of
  the hosting band; the user must also have a Band Membership in that band

This split follows `docs/community.md` §11: platform moderation (auditable,
via `AdminActionLog`) is a different thing from a band's own day-to-day
work. When a platform admin genuinely needs to operate inside a band —
support, an abandoned band, an emergency — the door is granting themselves
a membership at `/admin/bands/:id/privileges`, which is itself logged
(`grant_self_band_administrator`), rather than an implicit bypass.

Granted via the boolean `User#platform_admin` column — there is no
self-service UI or approval flow for it. Use the rake tasks in
`lib/tasks/users.rake`:

```bash
bin/rails "users:promote_admin[user@example.com]"
bin/rails "users:demote_admin[user@example.com]"
```

A `platform_admin` cannot be demoted or destroyed while they are the last
one (`User#ensure_not_demoting_last_platform_admin`,
`User#ensure_not_last_platform_admin`) — at least one must always remain.

---

## Authorization Rules

Every private resource must be authorized server-side.

Never rely on:

- hidden buttons
- frontend state
- URLs
- client-side checks

---

## Band Approval and the Store

Only an approved band sells. A pending, rejected, or suspended band's
products cannot be added to a cart or checked out, even through a direct
link, and a cart filled before a band was suspended is refused at checkout.

---

## Band Isolation

A user with administrative access to Band A
must never be able to:

- edit Band B
- access Band B private content
- modify Band B products
- modify Band B shipping destinations or rates
- view Band B private financial information
