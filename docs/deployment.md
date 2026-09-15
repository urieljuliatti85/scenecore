# Deployment

## Environments

### Development

Local machine.

### Staging

Used for:

- integration testing
- payment testing
- acceptance testing

**Status (2026-09-14): does not exist yet.** Only a `production` Railway
environment has been provisioned (project `scenecore`, services `web` and
`postgres`). The deployment flow below describes the intended process once
staging exists; today, `main` deploys straight to production with no
intermediate environment. Provisioning a real staging environment (its own
`web` + `postgres` services in Railway) is open work, not yet scoped as a
roadmap item.

### Production

Real users and real payments.

**Status (2026-09-14):** live. `web` service tracks the `main` branch,
single replica, region `ams`. No Active Storage volume is mounted (see
Storage below) and no dedicated Postgres volume was found either — both are
open risks on the current live deployment, not just planning gaps.

---

## Infrastructure

Application:

Railway

Database:

PostgreSQL

### Database persistence — CRITICAL, unresolved (2026-09-15)

The `postgres` service runs the raw `postgres:16` image with **no volume
attached** (`volumeMounts: []`, verified against the live environment; its
deploy logs show `initdb` running and no "Mounting volume" line, which the
`web` service's logs do show). Postgres is therefore writing to the
container filesystem: **a restart or redeploy of that service destroys the
entire database** — users, bands, albums, posts, follows.

Railway's backup feature operates on volumes, so no backup can be
configured until this is fixed either.

**Fixing it requires care, in this order.** Mounting an empty volume at
`/var/lib/postgresql/data` masks the existing data directory; Postgres
then runs `initdb` into the empty volume and the database comes up empty,
with the old data unreachable and lost at the next restart.

1. Dump the current database first:

   ```
   railway link -p 47c6b007-01a1-49a8-ab16-04e319bf918d
   railway run --service postgres sh -c \
     'pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB" --no-owner --no-acl' \
     > scenecore-prod-backup-$(date +%Y%m%d-%H%M).sql
   ```

   (`railway run` injects the service's variables, so the password never
   appears on the command line.) Verify the dump is non-empty before
   continuing.

2. Create a volume on `postgres` mounted at `/var/lib/postgresql/data`.
   The service restarts and comes up with an empty database.

3. Restore the dump into it, then confirm the app reads real data again.

Until step 2 is done, treat production data as disposable and avoid
restarting or redeploying the `postgres` service.

---

## Background jobs and cache

**Status (2026-09-15): in-process, deliberately.**

`production.rb` previously configured Solid Queue (jobs), Solid Cache
(cache) and Solid Cable (Action Cable), but none of them worked:
`config/database.yml` declares a single database with no `queue`/`cache`/
`cable` connections, so `db/queue_schema.rb` and `db/cache_schema.rb` are
never loaded and those tables do not exist. Every job enqueue and cache
write in production was hitting a missing table. Verified against the live
environment: the project has only `web` and `postgres` services (no worker),
and `SOLID_QUEUE_IN_PUMA` — which `config/puma.rb` checks before starting
an in-Puma worker — is not set, so nothing would have drained the queue
even with the tables present.

Now: `:async` for Active Job, `:memory_store` for cache, `async` for
Action Cable. These are in-process, which fits the current shape of
production (one `web` replica, no application-owned jobs — the only job
enqueued today is Active Storage's `AnalyzeJob`, and nothing uses Action
Cable at all).

Migration trigger: in-process adapters are per-process, so queued work is
lost on restart and never shared between replicas. Before adding a second
`web` replica, or any job that must survive a restart, add the `queue` and
`cache` connections to `config/database.yml` (so `db:prepare` creates the
tables), then move back to Solid Queue/Cache and run a worker — either
`SOLID_QUEUE_IN_PUMA=true` on `web`, or a dedicated worker service.
`spec/models/production_backends_spec.rb` fails if production is pointed
back at a Solid backend before that connection exists.

---

## Storage

**Status (2026-09-15): resolved for production.** A Railway Volume
(`scenecore-active-storage`, 500MB, region `ams`) is mounted on the `web`
service at `/rails/storage`, and `ACTIVE_STORAGE_PATH=/rails/storage` is
set on that service. `config/storage.yml` has a `production` entry rooted
at that path (falling back to `Rails.root/storage` when the variable is
unset, so the config is safe to run anywhere), and `production.rb` uses
`config.active_storage.service = :production`.

Before this, `production.rb` used `:local`, rooted at the container
filesystem — every band photo, album cover and post image uploaded to
production was discarded on the next deploy.

Staging storage remains unresolved, because no staging environment exists
(see ROADMAP.md 1.1).

Decision behind it: use a Railway Volume mounted on the `web`
service for `production`/`staging` Active Storage, rather than external
object storage (S3/Cloudflare R2/GCS) — SceneCore's storage need today is
small (band photos, album covers only; no video/large media until
ROADMAP.md 10.2 ships) and staying on Railway avoids a second provider
account. The `web` service is currently single-replica, so a
single-instance Disk volume introduces no cross-instance consistency
problem yet.

Migration trigger for object storage (S3/R2/GCS — `config/storage.yml`
already has commented-out templates for both): if the `web` service is ever
scaled to multiple replicas, or ROADMAP.md 10.2 (post media: images,
videos, downloads) ships and storage volume grows significantly, a
Disk-backed volume no longer fits and should be replaced with S3-compatible
object storage instead.

Implemented 2026-09-15. Note that the volume is attached to the `web`
service, so it is only reachable from that container — a `staging`
environment would need its own volume, and scaling `web` past one replica
breaks the single-writer assumption (see the migration trigger above).

---

## Environment Variables

Required variables:

- DATABASE_URL
- SECRET_KEY_BASE
- [provider credentials]
- [email credentials]

Currently set on the `web` service in Railway (verified 2026-09-15 against
the live environment): `APP_HOST`, `DATABASE_URL`, `PORT`, `RAILS_ENV`,
`RAILS_MASTER_KEY`, plus the `RAILWAY_*` variables Railway injects itself.
No storage or email provider credentials are configured yet, and
`SOLID_QUEUE_IN_PUMA` is deliberately not set (see Background jobs above).

Never commit secrets.

---

## Deployment Flow

feature branch
↓
pull request
↓
CI
↓
staging
↓
human approval
↓
main
↓
production
↓
migration
↓
smoke test
↓
monitoring

---

## Rollback

[Describe rollback procedure]

---

## Smoke Tests

- application loads
- authentication works
- database connection works
- background jobs work
- file uploads work
- payment webhooks work