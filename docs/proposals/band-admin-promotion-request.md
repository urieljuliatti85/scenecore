# Proposal: Band Member requests Band Administrator promotion

Status: **proposed, not approved** — do not implement until this is signed
off (see `CLAUDE.md`, Scope Control).

## Problem

Today, promoting a `BandMembership` to `administrator` requires either:

- an existing Band Administrator of that band changing the member's role
  (`docs/permissions.md`: a Band Administrator can "invite, remove, and
  change the role of their band's members"); or
- a Platform Administrator doing it directly via
  `Admin::PrivilegesController#update`.

There is no path for a Band Member to *ask* to be promoted when, for
example, the band has no other active administrator willing or available
to promote them, or the band wants a neutral third party (the platform)
to arbitrate who becomes an administrator.

This is a new capability. It is not described in `docs/permissions.md`,
`docs/band-admin.md`, `docs/memberships.md`, or `ROADMAP.md`.

## Proposed flow

1. A Band Member, from a band they already hold a `BandMembership` for,
   submits a request via a form ("Request administrator access") naming
   that band. A member cannot request promotion for a band they don't
   already belong to.
2. The request is visible to Platform Administrators only, in the
   `Admin::*` namespace (not to the band's own administrators — the
   point is platform arbitration, not routing around the band).
3. A Platform Administrator can:
   - **approve** — promotes the underlying `BandMembership` to
     `administrator` (reusing the existing role-change path/invariants
     in `BandMembership`, e.g. no impact on "last administrator" rules
     since this only adds an administrator).
   - **reject** — the request is denied; the member stays a `member`.
   - **revoke** — the *requester* (or a Platform Administrator, before a
     decision is made) withdraws a still-pending request. This does not
     touch an already-approved promotion; demoting an existing
     administrator is a separate, already-existing action
     (`Admin::PrivilegesController#update` / a band's own administrator
     changing a member's role) and is out of scope for this proposal.
4. A member with a pending request cannot submit another one for the same
   band (one pending request per membership).

## Data model

New model, following the existing `Report` pattern (a member-initiated
escalation to the Platform Administrator, `app/models/report.rb`):

```ruby
class BandAdminRequest < ApplicationRecord
  belongs_to :band_membership

  enum :status, { pending: "pending", approved: "approved", rejected: "rejected", revoked: "revoked" },
       default: :pending, validate: true
end
```

- `band_membership_id` — the membership requesting promotion (gives us
  the user and the band without duplicating either).
- One pending request per `band_membership` (uniqueness scoped on
  `band_membership_id` where `status: pending`, enforced at the DB level
  per `CLAUDE.md` database rules, not just a model validation).

## Authorization

- Creating a request: the `BandMembership`'s own user, and only for a
  `member`-role membership they hold (an existing administrator has no
  reason to request what they already have).
- Revoking a pending request: the requester, or a Platform Administrator.
- Approving/rejecting: Platform Administrator only (`user.platform_admin?`),
  mirroring `BandPolicy#approve?`/`#reject?`.
- No band-scoped administrator gets visibility or action on another
  band's requests — enforced by the `Admin::*` namespace already 404ing
  for non-platform-admins.

## Decisions

1. **Where the request form lives**: on the band's page — the member sees
   it there because they already belong to that band, without requiring
   any existing admin access.
2. **Notification**: the requester is emailed when a Platform Administrator
   approves or rejects the request. The codebase's only existing mail
   pattern is `ContactMailer` (`app/mailers/contact_mailer.rb`) —
   store-then-mail, `deliver_later`, failure logged/captured but never
   loses the underlying record or blocks the response. A new
   `BandAdminRequestMailer` (or a method added there if it fits better
   once the code is inspected) follows the same shape. There is no
   in-app notification system in this codebase (no inbox/notification
   model) — introducing one is out of scope for this proposal; email is
   the only mechanism used.
3. **Resubmission after rejection**: not blocked. A member may submit a
   new request immediately after a rejection (still subject to "one
   pending request per membership" — they can't have two open requests
   at once, but a `rejected` one doesn't stop a new `pending` one).

## Explicitly out of scope

- Demoting an existing administrator ("revoke" here only ever means
  cancelling a *pending request*, not removing an administrator's role).
- Any band-level visibility into these requests — this is a
  member-to-platform flow only.
- An in-app notification/inbox system — email only (see Decisions above).

## Implementation plan (for approval)

Mirrors the existing `Report` / `ReportsController` /
`Admin::ReportsController` split (member-facing escalation vs. platform
decision), and `BandPolicy#approve?`/`#reject?` for the platform-admin-only
gate.

1. **Migration**: `band_admin_requests` table —
   `band_membership_id` (FK, indexed), `status` (string, default
   `"pending"`, DB check constraint for the four enum values, per
   `CLAUDE.md` database rules), timestamps. A partial unique index on
   `band_membership_id` where `status = 'pending'` enforces "one pending
   request per membership" at the DB level, not just in a model
   validation.
2. **Model**: `BandAdminRequest` — `belongs_to :band_membership`, status
   enum as in the Data model section above. Validates the membership is
   `member` role (not already `administrator`) on create.
3. **Policy**: `BandAdminRequestPolicy` —
   `create?`: the membership's own user, and only while it is `member`
   role (mirrors `ReportPolicy#create?`'s shape).
   `revoke?`: the requester, or `user&.platform_admin?`.
   `approve?`/`reject?`: `user&.platform_admin?` only (mirrors
   `BandPolicy#approve?`/`#reject?`).
4. **Member-facing controller**: `BandAdminRequestsController` (top-level,
   like `ReportsController`, not nested under `Admin::`) —
   `create` (from the band's own page — the member must already pass
   `BandPolicy#show?` for that band) and `revoke` (member cancels their
   own pending request). Redirects back to the band's page with a
   notice/alert, same pattern as `ReportsController`.
5. **Admin-facing controller**: `Admin::BandAdminRequestsController` <
   `Admin::BaseController` — `index` (pending requests, or filterable by
   status), `approve` (wraps promoting the `BandMembership` to
   `administrator` — reuses `BandMembership`'s existing role-change path
   so its invariants apply unchanged, then marks the request `approved`),
   `reject` (marks `rejected`), `revoke` (platform admin can also
   withdraw a pending request, per the Authorization section).
6. **Mailer**: extend the existing mail pattern — a new mailer (or a
   method on an existing one, decided once mailer conventions are
   re-checked at implementation time) sends the requester an email on
   approval and on rejection. `deliver_later`, failure logged/captured
   without blocking the controller action or losing the decision — same
   shape as `ContactMessagesController#deliver`.
7. **View**: on the band's page (`app/views/bands/show.html.erb` or a
   partial it renders), a "Request administrator access" button/form
   shown when `policy(band_admin_request).create?` — i.e., to a
   `member`-role Band Member without a pending request already open.
   Once pending, show the pending state and a "Cancel request" (revoke)
   action instead of the request button. This sits in the member-facing
   area of the page, not inside the `manage:` tabs gated by
   `policy(@band).update?` (a plain member has no access to those tabs).
8. **Admin view**: a page under `Admin::*` (e.g.
   `admin/band_admin_requests/index.html.erb`, linked from the admin
   sidebar/dashboard the way `Admin::ReportsController` presumably is)
   listing pending requests with approve/reject actions, and past
   decisions for context.
9. **Tests**: model (`BandAdminRequest` validations, one-pending-per-
   membership constraint), policy (`BandAdminRequestPolicy`), request
   specs for both controllers (create/revoke as the member; approve/
   reject/revoke as the platform admin; 404/403 for everyone else),
   mailer test for both outcomes.

## Explicitly still open

- Exact route/URL shape and admin navigation entry point — decided by
  inspecting `config/routes.rb` and the admin sidebar layout at
  implementation time, not guessed here.
- Whether `BandAdminRequestsController#create`/`#revoke` live at
  `/bands/:band_id/admin_request` (nested) or flatter
  (`/band_admin_requests`) — follows whatever `ReportsController`'s
  nesting convention turns out to generalize to on inspection.
