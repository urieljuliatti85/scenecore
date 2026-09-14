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
- manage band's events
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

---

## Authorization Rules

Every private resource must be authorized server-side.

Never rely on:

- hidden buttons
- frontend state
- URLs
- client-side checks

---

## Band Isolation

A user with administrative access to Band A
must never be able to:

- edit Band B
- access Band B private content
- modify Band B products
- view Band B private financial information