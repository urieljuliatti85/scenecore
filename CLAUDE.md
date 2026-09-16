# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

SceneCore is a Rails monolith for a music-first platform where independent
bands build a direct, ongoing relationship with their fans.

Product promise: Your band. Your fans. Your home.

SceneCore is the band's digital home. It connects music, content, commerce,
subscriptions, and events around one continuous band–fan relationship. It is
not positioned as a generic all-in-one tool, a streaming replacement, or a
generic creator-membership platform.

The platform may include:

- music
- exclusive content
- subscriptions
- merchandise
- tickets
- band management

The MVP scope is defined by `docs/product.md`.

The implementation order is defined by `ROADMAP.md`.

### Product positioning guardrails

When evaluating product or UX decisions, optimize for the experience SceneCore
intends to make significantly better: helping a band turn discovery elsewhere
into a durable, direct fan relationship in its own digital home.

- Spotify is primarily a discovery and streaming channel. SceneCore may use it
  as an entry point or integration; it does not need to replace it.
- Bandcamp is primarily a direct-purchase destination for music and
  merchandise. SceneCore must not be described merely as "Bandcamp with more
  features."
- Patreon is primarily a membership and exclusive-content platform. SceneCore
  keeps music and the band's identity at the center rather than treating the
  band as a generic content creator.

The intended journey is discovery → SceneCore relationship → ongoing support,
purchases, subscriptions, community, and events.

"The scene" is a promising future direction: bands + fans + the musical scene.
It is not authorization to build scene graphs, genre communities, social
feeds, recommendations, or other social-network features in the MVP.

For every proposed feature, ask:

1. Does it strengthen the ongoing band–fan relationship?
2. Does it reinforce the band's digital home and music-first identity?
3. Is it already inside the approved MVP?

A "no" to question 3 means document the proposal and wait for explicit approval.

## Documentation hierarchy

```text
CLAUDE.md   → development rules and agent behavior
ROADMAP.md  → implementation order and project progress
docs/       → detailed feature specifications
README.md   → project setup and usage
```

Before implementing a roadmap item:

1. Read the corresponding documentation in `docs/`.
2. Inspect the existing codebase.
3. Do not assume that a model, controller, service, route, or integration exists.
4. Reuse existing architecture when appropriate.
5. Implement the smallest change necessary.
6. Run the relevant tests.
7. Do not implement features outside the current roadmap item.

When a roadmap item references a document such as `docs/band-admin.md`, read
that document before implementing the feature.

`docs/` defines the functional requirements. `ROADMAP.md` defines
implementation order. `CLAUDE.md` defines development behavior and
constraints.

When these documents appear to conflict:

1. Preserve explicit project constraints in `CLAUDE.md`.
2. Identify the conflict.
3. Do not silently choose an architectural interpretation.
4. Ask for clarification when the conflict materially affects implementation.

## Commands

Setup (Postgres via Docker, deps, DB):

```bash
docker compose up -d
cp .env.example .env
bin/setup
```

Run the app (Rails server + Tailwind watcher, per `Procfile.dev`):

```bash
bin/dev
```

Tests (RSpec: model, policy, request, service, system specs under `spec/`):

```bash
bundle exec rspec                                              # full suite
bundle exec rspec spec/models/band_spec.rb                     # single file
bundle exec rspec spec/models/band_spec.rb:42                  # single example by line
bundle exec rspec --exclude-pattern "spec/system/**/*_spec.rb" # skip browser-driven specs
```

Lint (RuboCop, Rails Omakase style) and security scans (mirrors CI in `.github/workflows/ci.yml`):

```bash
bundle exec rubocop
bin/brakeman --no-pager
bin/bundler-audit
bin/importmap audit
```

Git hooks (installed via `bundle exec overcommit --install`) run RuboCop on commit and RSpec on push — see `.overcommit.yml`.

## Architecture

Standard Rails app structure (`app/models`, `app/controllers`, `app/policies`,
`app/services`, `app/jobs`, `app/views`) — see `docs/architecture.md` for the
full stack (Hotwire/Turbo+Stimulus, Importmap, Tailwind, Solid Queue/Cache/Cable,
Kamal) and the intended domain boundaries (Identity, Bands, Music, Content,
Commerce, Subscriptions, Events).

Key patterns already established in code:

- **Authorization is Pundit-based**, one policy per model in `app/policies/`.
  `ApplicationController` includes `Pundit::Authorization` and denies by
  default (`ApplicationPolicy` returns false unless overridden). Band-scoped
  authorization checks the caller's `BandMembership` role for that specific
  band (see `BandPolicy`) — there is no global "band admin" flag, so
  authorization must always be checked per-band. Platform-wide actions check
  `user.platform_admin?` (a boolean column on `User`), separate from any band
  role.
- **Admin namespace** (`Admin::*` controllers, `app/views/admin/`) is gated by
  `Admin::BaseController#require_platform_admin`, which 404s (not 403s) for
  non-admins.
- **`BandMembership`** enforces "last administrator" invariants in
  `before_destroy`/`before_update` callbacks (a band can never be left
  without an administrator) — extend these callbacks rather than duplicating
  the check elsewhere.
- **`HasImage`** (`app/models/concerns/has_image.rb`) is the shared pattern
  for `has_one_attached` image fields with content-type/size validation;
  reuse it for new image attachments instead of re-validating ad hoc.
- **Spotify integration** (`app/services/spotify_client.rb`) is the only
  external API call in the app. It uses Client Credentials OAuth (no
  user-level Spotify auth) and caches the access token in `Rails.cache`.
  Track/album audio is never hosted by SceneCore — playback links out to
  Spotify.
- **Slugs**: bands are addressed publicly by a generated, unique slug (see
  `Band#generate_slug`), not `id`. Public routes (`/:slug`,
  `/:slug/albums/:id`) are declared last in `config/routes.rb` so they don't
  shadow other routes.
- **Draft vs. published visibility**: albums, tracks, and posts use an
  explicit status/enum to gate public visibility — draft records must never
  be reachable from public controllers regardless of direct URL access (see
  `docs/permissions.md` and `docs/database.md`).

Reference docs worth reading before touching a given area:

- `docs/product.md` — MVP scope
- `docs/permissions.md` — role matrix: Visitor/Fan/Band Member/Band Administrator/Platform Administrator
- `docs/database.md` — data model/rules per table
- `docs/payments.md` — money/webhook rules for the not-yet-built commerce area
- `docs/decisions.md` — ADRs
- `docs/deployment.md` — Railway-based deploy flow
- `docs/band-admin.md`, `docs/memberships.md`, `docs/community.md` — feature specs for those domains

## Mandatory Workflow

Before implementing any feature:

1. Read CLAUDE.md.
2. Read the relevant product documentation.
3. Read the relevant roadmap item or GitHub issue.
4. Inspect the existing code.
5. Produce an implementation plan.
6. STOP and wait for approval.

Never implement a feature immediately when the task is ambiguous.

## Rails Principles

- Prefer Rails conventions.
- Keep controllers thin.
- Keep domain logic close to the domain.
- Use service objects only when they provide real value.
- Avoid premature abstractions.
- Avoid unnecessary APIs.
- Prefer a Rails monolith for the MVP.
- PostgreSQL is the source of truth.
- Do not introduce architecture that is not required by the current MVP.

## Database

- Money must be stored as integer cents.
- Timestamps must be stored correctly and handled consistently.
- Add appropriate indexes.
- Add database constraints where appropriate.
- Never rely exclusively on model validations for data integrity.
- Do not change existing data structures without explaining the impact.

## Authorization

- Authorization must always happen on the server.
- Never rely exclusively on UI hiding, disabled buttons, frontend checks, or URL obscurity.
- A band must never access or modify another band's private resources.
- Private content must remain protected even if a user knows its URL.

## Security

- Never expose secrets.
- Never commit credentials.
- Never log sensitive payment information.
- Never store complete card information.
- Validate webhook authenticity.
- Webhooks must be idempotent.
- Treat uploaded files as untrusted input.

## Testing

- Every business rule requires tests.
- Prefer testing behavior over implementation details.
- For each feature, consider: model tests, authorization tests, request/system tests, edge cases, failure scenarios.
- Run the relevant test suite after implementation.
- Run linting before considering a task complete.

## Scope Control

- Do not invent features.
- Do not expand the MVP.
- Do not refactor unrelated code.
- Do not introduce dependencies unless necessary.
- Do not use the positioning language as permission to invent features. In
  particular, the future "scene" opportunity does not expand the current MVP.

If a requirement is ambiguous:

1. Identify the ambiguity.
2. Explain the possible interpretations.
3. Recommend one if appropriate.
4. STOP and ask for approval.

## Git

- Do not commit unless explicitly instructed.
- Do not push to the remote repository unless explicitly instructed.
- Do not modify unrelated files.
- Keep changes small and focused.

## Completion Criteria

A task is not complete until: implementation is finished; tests pass; lint
passes; acceptance criteria are satisfied; security/authorization
implications were checked; no unrelated functionality was changed.

At the end, report: files changed; database changes; tests executed; lint
executed; relevant decisions; known limitations.
