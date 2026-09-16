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

A band's release, shown as cover and title and linking out to Spotify for
listening.

### Attributes

- band_id
- title
- status
- cover
- spotify_id
- spotify_cover_url
- created_at
- updated_at

### Rules

- An album belongs to one band.
- An album is a pointer to Spotify, not a track listing. SceneCore stores
  the album's Spotify id at import and derives the listen link from it;
  it does not mirror the album's tracks.
- Draft albums are not publicly accessible.
- Published albums may be publicly accessible.

---

## Tracks

**Superseded 2026-09-16.** Albums link out to Spotify instead of
mirroring its catalogue, so nothing creates, reads or renders a track any
more.

The table and model are deliberately kept for now: they still hold the
rows imported under the old behaviour, and dropping them would be an
irreversible migration for a decision only days old. Remove both once the
new shape has settled.

The previous rules were: a track belonged to one album (and through it to
one band); its audio was never hosted by SceneCore but linked to the
corresponding Spotify track, played through Spotify's embed; draft tracks
were not publicly accessible and published ones could be.

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
  └── (links out to Spotify; no Tracks association since 2026-09-16)