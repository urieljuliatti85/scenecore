# SceneCore

**Your band. Your fans. Your home.**

SceneCore is a music-first platform where independent bands create a digital
home and build a direct, ongoing relationship with their fans through music,
content, merchandise, subscriptions, and events.

This repository contains the Rails monolith for the SceneCore MVP. See
`CLAUDE.md` for project conventions and `docs/product.md` for product scope and
positioning.

## Setup

Ruby version: see `.ruby-version`.

1. Create the persistent PostgreSQL volume once, then start PostgreSQL:

   ```
   docker volume create scenecore_scenecore_postgres_data
   docker compose up -d
   ```

   The volume is external to Docker Compose, so `docker compose down -v`
   cannot delete the local database. Creating an existing volume again is
   safe and leaves its contents unchanged.

2. Copy the example environment file:

   ```
   cp .env.example .env
   ```

3. Install dependencies and prepare the database:

   ```
   bin/setup
   ```

4. Install Git hooks (RuboCop on commit, RSpec on push):

   ```
   bundle exec overcommit --install
   ```

## Running the app

```
bin/dev
```

## Local database backup

Create a backup before database or Docker maintenance:

```
mkdir -p tmp/backups
docker compose exec -T db pg_dump -U scenecore -Fc scenecore_development > tmp/backups/scenecore_development.dump
```

Restore it into an empty local development database:

```
docker compose exec -T db pg_restore -U scenecore -d scenecore_development --clean --if-exists < tmp/backups/scenecore_development.dump
```

## Tests

```
bundle exec rspec
```

## Lint

```
bundle exec rubocop
```
