# Database

## Users

### Purpose

Represents a platform user.

### Attributes

- id
- email
- name
- created_at
- updated_at

---

## Bands

### Purpose

Represents a musical project.

### Attributes

- id
- name
- slug
- description
- status
- created_at
- updated_at

---

## BandMemberships

### Purpose

Connects users and bands.

### Attributes

- user_id
- band_id
- role

### Rules

- A user may belong to multiple bands.
- A band may have multiple members.
- A band may have multiple administrators.

---

## Tracks

### Attributes

- band_id
- title
- status
- audio
- created_at
- updated_at

### Rules

- A track belongs to one band.
- Draft tracks are not publicly accessible.
- Published tracks may be publicly accessible.

---

## Orders

### Rules

- An order belongs to one band in the MVP.
- Monetary values are stored in cents.
- Order state must be explicit.

---

## Relationships

User
  └── has_many BandMemberships

Band
  ├── has_many BandMemberships
  ├── has_many Tracks
  └── has_many Products