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

### Database persistence — resolved 2026-09-15

The `postgres` service stores its data on the Railway Volume
`scenecore-postgres-data` (500MB, region `ams`), mounted at
`/var/lib/postgresql/data`, with **`PGDATA` set to
`/var/lib/postgresql/data/pgdata`**.

That `PGDATA` variable is not optional — see below.

Before this, the service ran the raw `postgres:16` image with no volume at
all, writing to the container filesystem, so any restart or redeploy
destroyed the entire database. Verified fixed by restarting the service
and confirming the data survived.

**`PGDATA` must point at a subdirectory of the mount, not the mount
itself.** A Railway volume arrives containing a `lost+found` directory, so
`initdb` refuses to use the mount point directly and the service
crash-loops with:

```
initdb: error: directory "/var/lib/postgresql/data" exists but is not empty
initdb: detail: It contains a lost+found directory, perhaps due to it being a mount point.
initdb: hint: Using a mount point directly as the data directory is not recommended.
Create a subdirectory under the mount point.
```

This is exactly what happened on the first attempt here. Setting
`PGDATA=/var/lib/postgresql/data/pgdata` resolved it.

**Dumping the database.** `railway run` executes locally and cannot reach
the database (it only has an internal Railway address, and there is no TCP
proxy). Run `pg_dump` from inside the `web` container instead, which has
`postgresql-client` installed and reaches the database over the internal
network:

```
railway ssh --service web sh -c 'pg_dump "$DATABASE_URL" --no-owner --no-acl' \
  > scenecore-prod-backup-$(date +%Y%m%d-%H%M).sql
```

Restore the same way, with `psql` in place of `pg_dump`. Note that a full
dump also contains `CREATE TABLE` statements, which conflict with the
tables `db:prepare` creates on boot — to restore data only, extract the
relevant `COPY` blocks. After restoring rows with explicit ids, reset the
sequence or the next insert collides:

```
SELECT setval(pg_get_serial_sequence('users', 'id'), (SELECT MAX(id) FROM users));
```

### Scheduled backups

A `postgres-backup` service runs a daily dump at 03:00 UTC.

- Image `postgres:16-alpine` (it ships `pg_dump`), `restartPolicyType:
  NEVER` and `cronSchedule: 0 3 * * *`, so it runs once and exits — the
  shape Railway expects for a cron service.
- Dumps land on **`scenecore-backups`**, a volume separate from the
  database's own `scenecore-postgres-data`. That separation is the point:
  a backup sharing the database's volume would be lost along with it.
- The 7 most recent dumps are kept; older ones are deleted each run. Files
  under 1KB are cleared first, so a truncated dump doesn't count toward
  retention.
- `DATABASE_URL` is assembled from `${{postgres.*}}` references, so the
  dump travels over Railway's private network and the password is not
  duplicated into a second variable.

Railway's own scheduled-backup feature is *not* used — it is not available
on this account (its docs describe it as "still under development"). If it
becomes available, it is worth preferring: it snapshots the volume itself
and supports staged restores.

**Restoring a dump** (custom format, so `pg_restore` rather than `psql`):

```
railway ssh --service postgres-backup sh -c \
  'pg_restore --clean --if-exists --no-owner -d "$DATABASE_URL" /backups/<file>.dump'
```

One caveat, untested: `--clean` drops existing objects before recreating
them. Restoring onto a live database is destructive by design — take a
fresh dump first.

**Note on the entrypoint.** The plain `postgres:16` image cannot be used
here: its ENTRYPOINT intercepts the start command and tries to boot a
database server, failing with "Database is uninitialized and superuser
password is not specified". The `-alpine` variant with an explicit
`/bin/sh -c` start command and the full `/usr/local/bin/pg_dump` path
works.

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
the live environment): `ACTIVE_STORAGE_PATH`, `APP_HOST`, `DATABASE_URL`,
`PORT`, `RAILS_ENV`, `RAILS_MASTER_KEY`, plus the `RAILWAY_*` variables
Railway injects itself. On the `postgres` service: `PGDATA` (see Database
persistence above) and the `POSTGRES_*` credentials.

Deliberately not set: `SOLID_QUEUE_IN_PUMA` (see Background jobs above).

**Not yet set, and needed:**

- `SENTRY_DSN` on `web` — error monitoring is wired up but inert without
  it. Nothing is reported until this is set; see the Monitoring note
  below.
- Email provider credentials — see Email below. No mail is sent until
  they are set.

## Email

**Status (2026-09-15): wired up, not yet activated.**

Production used to be worse than unconfigured: `delivery_method` defaulted
to `:smtp` against `localhost:25` with nothing listening, and
`raise_delivery_errors` defaults to `true` — so a password reset raised and
the user got a **500**. Both sender addresses were still Rails'/Devise's
generated placeholders.

Now `config/environments/production.rb` only attempts delivery when
`SMTP_ADDRESS` is present. Without it, `perform_deliveries` is off and
nothing raises; the password-reset page still reports success, which is
what Devise does for unknown addresses anyway.

To activate, set these on the `web` service:

| Variable | Value |
|---|---|
| `SMTP_ADDRESS` | `smtp.resend.com` |
| `SMTP_PORT` | `587` (the default if unset) |
| `SMTP_USER_NAME` | `resend` |
| `SMTP_PASSWORD` | the Resend API key |
| `MAIL_FROM` | a verified sender, e.g. `no-reply@yourdomain` |

Resend requires the sending domain to be verified before it will accept
mail from it; their test domain works for a first check. `MAIL_FROM` feeds
both `Devise.mailer_sender` and `ApplicationMailer`'s default `from`.

What depends on this today: Devise password reset (`:recoverable` is
enabled and reachable from the sign-in page). Adding email confirmation for
address changes — the gap recorded in Phase 13 — also waits on it.

## Monitoring

Errors are reported to Sentry via `sentry-rails`, configured in
`config/initializers/sentry.rb`. The initializer returns early unless
`SENTRY_DSN` is present, so development, test and CI stay offline and make
no network calls.

`send_default_pii` is deliberately off: request bodies, cookies and user
details are not sent off-platform. Routing and record-not-found errors are
excluded, since those are mostly bots probing unknown paths.

To activate: create a Sentry project (Rails platform) and set `SENTRY_DSN`
on the `web` service. No code change or redeploy of the image is needed —
setting the variable restarts the service, which picks it up.

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