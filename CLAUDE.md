# CLAUDE.md

## Project

SceneCore is a Rails monolith for a multi-band music platform.

The platform may include:

- music
- exclusive content
- subscriptions
- merchandise
- tickets
- band management

The MVP scope is defined by `docs/product.md`.

The implementation order is defined by `ROADMAP.md`.

---

## Mandatory Workflow

Before implementing any feature:

1. Read `CLAUDE.md`.
2. Read the relevant product documentation.
3. Read the relevant roadmap item or GitHub issue.
4. Inspect the existing code.
5. Produce an implementation plan.
6. STOP and wait for approval.

Never implement a feature immediately when the task is ambiguous.

---

## Rails Principles

- Prefer Rails conventions.
- Keep controllers thin.
- Keep domain logic close to the domain.
- Use service objects only when they provide real value.
- Avoid premature abstractions.
- Avoid unnecessary APIs.
- Prefer a Rails monolith for the MVP.
- PostgreSQL is the source of truth.

Do not introduce architecture that is not required by the current MVP.

---

## Database

- Money must be stored as integer cents.
- Timestamps must be stored correctly and handled consistently.
- Add appropriate indexes.
- Add database constraints where appropriate.
- Never rely exclusively on model validations for data integrity.
- Do not change existing data structures without explaining the impact.

---

## Authorization

Authorization must always happen on the server.

Never rely exclusively on:

- UI hiding
- disabled buttons
- frontend checks
- URL obscurity

A band must never access or modify another band's private resources.

Private content must remain protected even if a user knows its URL.

---

## Security

- Never expose secrets.
- Never commit credentials.
- Never log sensitive payment information.
- Never store complete card information.
- Validate webhook authenticity.
- Webhooks must be idempotent.
- Treat uploaded files as untrusted input.

---

## Testing

Every business rule requires tests.

Prefer testing behavior over implementation details.

For each feature, consider:

- model tests
- authorization tests
- request/system tests
- edge cases
- failure scenarios

Run the relevant test suite after implementation.

Run linting before considering a task complete.

---

## Scope Control

Do not invent features.

Do not expand the MVP.

Do not refactor unrelated code.

Do not introduce dependencies unless necessary.

If a requirement is ambiguous:

1. identify the ambiguity;
2. explain the possible interpretations;
3. recommend one if appropriate;
4. STOP and ask for approval.

---

## Git

Do not commit unless explicitly instructed.

Do not push to the remote repository unless explicitly instructed.

Do not modify unrelated files.

Keep changes small and focused.

---

## Completion Criteria

A task is not complete until:

- implementation is finished;
- tests pass;
- lint passes;
- acceptance criteria are satisfied;
- security/authorization implications were checked;
- no unrelated functionality was changed.

At the end, report:

- files changed;
- database changes;
- tests executed;
- lint executed;
- relevant decisions;
- known limitations.