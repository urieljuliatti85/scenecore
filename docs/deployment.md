# Deployment

## Environments

### Development

Local machine.

### Staging

Used for:

- integration testing
- payment testing
- acceptance testing

### Production

Real users and real payments.

---

## Infrastructure

Application:

Railway

Database:

PostgreSQL

---

## Environment Variables

Required variables:

- DATABASE_URL
- SECRET_KEY_BASE
- [provider credentials]
- [email credentials]

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