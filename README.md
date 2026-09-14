# SceneCore

Rails monolith for a multi-band music platform. See `CLAUDE.md` for
project conventions and `docs/product.md` for product scope.

## Setup

Ruby version: see `.ruby-version`.

1. Start PostgreSQL:

   ```
   docker compose up -d
   ```

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

## Tests

```
bundle exec rspec
```

## Lint

```
bundle exec rubocop
```
