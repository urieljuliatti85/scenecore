# Product Specification

## Overview

SceneCore is a Rails monolith that lets independent bands run their own
presence on a shared platform: a public band page, music releases, and
(in later phases) exclusive content, merchandise, subscriptions, and
ticketed events.

This document defines the MVP: the smallest usable slice of the platform,
corresponding to ROADMAP.md Phases 1–3 (Foundation, Accounts & Bands,
Public Band & Music). Anything tied to a later phase is explicitly out of
scope until that phase is reached.

---

## User Roles

### Fan / Listener

- Unauthenticated or authenticated visitor.
- Can browse public band pages and listen to published tracks.
- Can create an account to follow bands.
- Becomes a **Subscriber** only once paid tiers exist (Phase 6 — out of
  scope for MVP).

### Band Member

- Belongs to exactly one band.
- Can manage that band's content, subject to their role within the band
  (member vs. administrator).
- A band must never access or modify another band's private resources
  (see CLAUDE.md — Authorization).

### Band Administrator

- A Band Member with elevated permissions within their own band:
  inviting/removing members, editing band profile, publishing releases.
- Scoped to their own band only.

### Platform Admin

- Staff role, not band-scoped.
- Approves new bands before they become public (ROADMAP Phase 2 —
  "Band approval").
- Full moderation/refund/report capabilities arrive in Phase 8 and are
  out of scope for MVP; for MVP, Platform Admin capability is limited to
  band approval.

---

## MVP Scope (ROADMAP Phases 1–3)

### In scope

**Foundation**
- Rails application, PostgreSQL, Tailwind, test suite, CI, staging
  environment. (Infrastructure — no user-facing behavior.)

**Accounts & Bands**
- User sign-up, sign-in, and profile.
- Band creation by an authenticated user, who becomes that band's first
  Band Administrator.
- Inviting/adding additional Band Members to a band.
- Band Administrator role, distinct from Band Member.
- Band approval workflow: a newly created band is not publicly visible
  until a Platform Admin approves it.
- Authorization rules enforced server-side: a band's private data and
  management actions are inaccessible to anyone outside that band.

**Public Band & Music**
- Public band page, reachable via a custom URL/slug.
- Releases containing one or more tracks.
- Audio player for published tracks.
- Draft vs. published state for releases (drafts are visible only to
  the band's own members).
- Fans can follow a band from its public page.

### Out of scope for MVP

Everything under ROADMAP Phases 4–8 is explicitly deferred:

- Exclusive content (posts, images, videos, visibility tiers) — Phase 4.
- Store, products, cart, checkout, orders — Phase 5.
- Subscriptions, recurring billing, payment webhooks — Phase 6.
- Events, ticketing, QR check-in — Phase 7.
- Moderation, refunds, reports, admin logs, production launch
  concerns — Phase 8.

Do not implement functionality from these phases while MVP work is in
progress, per CLAUDE.md — Scope Control.

---

## Core User Journeys (MVP)

### 1. Fan discovers and follows a band

1. Fan visits a band's public page via its custom URL.
2. Fan browses published releases and plays tracks in the audio player.
3. Fan creates an account (or signs in).
4. Fan follows the band from the public page.

### 2. Band signs up and creates a public page

1. User signs up / signs in.
2. User creates a band (becomes its Band Administrator).
3. Band remains unapproved and not publicly visible.
4. Platform Admin reviews and approves the band.
5. Once approved, the band's public page becomes reachable at its
   custom URL.

### 3. Band Administrator invites a member

1. Band Administrator adds another user as a Band Member of their band.
2. The new Band Member can access that band's management area, scoped
   to their permissions, and cannot access any other band's private
   resources.

### 4. Band publishes music

1. Band Member/Administrator creates a release in draft state.
2. Release is populated with one or more tracks.
3. Only band members can view/play a draft release.
4. Band Administrator publishes the release.
5. Published release and its tracks become visible and playable on the
   band's public page.

---

## Open Questions

These are not yet decided and should be resolved (and this document
updated) before the corresponding work begins:

- Exact permission differences between Band Member and Band
  Administrator beyond "can manage content" / "can invite members."
- What information is required/optional on a band's public profile.
- Custom URL/slug format, allowed characters, and collision handling.
- Supported audio file formats and any file size/duration limits.
- Whether Platform Admin band-approval has a rejection/feedback flow,
  or approve-only.
