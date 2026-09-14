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

## Albums

### Purpose

Groups a band's tracks into a release.

### Attributes

- band_id
- title
- status
- cover
- created_at
- updated_at

### Rules

- An album belongs to one band.
- An album has many tracks.
- Draft albums are not publicly accessible.
- Published albums may be publicly accessible.

---

## Tracks

### Attributes

- album_id
- title
- track_number
- status
- spotify_url
- created_at
- updated_at

### Rules

- A track belongs to one album (and, through it, to one band).
- A track's audio is not hosted by SceneCore — it links to the
  corresponding Spotify track, and playback uses Spotify's embed.
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
  ├── has_many Albums
  └── has_many Products

Album
  └── has_many Tracks