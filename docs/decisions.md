# Architecture Decisions

## ADR-001 — Rails Monolith

Status: Accepted

### Decision

The MVP will use a Rails monolith.

### Reason

The MVP does not justify microservices.

### Consequence

Domain boundaries should exist inside the monolith.

---

## ADR-002 — PostgreSQL

Status: Accepted

### Decision

PostgreSQL is the source of truth.

### Reason

The application requires relational data,
transactions and strong consistency.

---

## ADR-003 — Single-band Cart

Status: Accepted

### Decision

An order/cart can contain products from only one band.

### Reason

Simplifies checkout, fulfillment and revenue allocation
for the MVP.

---

## ADR-004 — Server-side Authorization

Status: Accepted

### Decision

All private resources must be authorized server-side.

### Reason

Frontend restrictions are not security boundaries.

---

## ADR-005 — Music-first Band Home Positioning

Status: Accepted

### Decision

SceneCore is positioned as a music-first digital home for the ongoing
relationship between an independent band and its fans.

SceneCore complements discovery, streaming, commerce, and membership platforms;
it does not require bands to replace Spotify, Bandcamp, Patreon, or equivalent
channels.

“The scene” is a future strategic opportunity, not part of the current MVP
unless separately validated and approved.

### Reason

“Everything for bands in one place” is generic and does not distinguish
SceneCore from existing products. Centering the persistent band–fan relationship
provides a clearer product outcome while keeping music at the core.

### Consequence

Product and UX decisions should strengthen the band's home and the fan's return
relationship. Competitor parity and feature count are not sufficient reasons to
expand scope. Scene-level social or discovery features must remain proposals
until explicitly approved.
