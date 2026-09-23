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

- approve bands
- moderate content
- manage platform-level resources

A Platform Administrator cannot reach a band's payment settings or its
Stripe account (the Payments tab, the Stripe Express dashboard link, or
Stripe Connect onboarding) merely because of the platform role. That is
the band's own money: as with refunds, the platform does not act as the
band's merchant (see the refunds ADR in `docs/decisions.md`). The user must
be an administrator of that band.

A Platform Administrator cannot validate an event ticket merely because of
the platform role. Ticket check-in is an operational action of the hosting
band; the user must also have a Band Membership in that band.

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
