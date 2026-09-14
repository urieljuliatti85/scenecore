# Architecture

## 1. Architecture Style

Rails monolith.

The application uses:

- Ruby on Rails (8.1)
- PostgreSQL
- Propshaft (asset pipeline)
- Importmap (JavaScript, no Node bundler)
- Hotwire (Turbo + Stimulus)
- Tailwind CSS
- Active Storage
- Solid Queue / Solid Cache / Solid Cable (database-backed jobs,
  cache, and websockets — Rails 8 defaults, no Redis dependency)
- Puma (web server) + Thruster
- Kamal (Docker-based deploys — present from `rails new`, not yet
  configured for a real target; see `docs/deployment.md`)

---

## 2. Architectural Principles

- Prefer Rails conventions.
- Keep controllers thin.
- Prefer models for domain behavior.
- Use service objects for complex workflows.
- Avoid premature abstractions.
- Avoid unnecessary APIs.
- PostgreSQL is the source of truth.

---

## 3. Main Domains

### Identity

Responsible for:

- users
- authentication
- sessions

### Bands

Responsible for:

- bands
- memberships
- administrators

### Music

Responsible for:

- releases
- tracks
- audio

### Content

Responsible for:

- posts
- exclusive content
- visibility

### Commerce

Responsible for:

- products
- cart
- orders
- payments

### Subscriptions

Responsible for:

- plans
- subscriptions
- billing

### Events

Responsible for:

- events
- tickets
- check-in

---

## 4. Application Structure

Controllers:

app/controllers/

Models:

app/models/

Services:

app/services/ (not created yet — per CLAUDE.md, service objects are
only introduced when they provide real value, not scaffolded up
front)

Jobs:

app/jobs/

Policies:

app/policies/ (not created yet — authorization approach/gem not yet
decided; see ROADMAP.md Phase 2)

---

## 5. External Services

[List integrations]

For each integration:

- purpose
- authentication
- API
- webhooks
- failure behavior