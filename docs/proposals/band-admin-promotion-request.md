# Proposal: request to join and administer a band

Status: **approved** — see decisions below. Supersedes an earlier draft
of this document, which modeled a different, narrower feature (see
"Revision history").

## Problem

There is no path today for someone who identifies as being part of a
band — e.g. an actual band member who has never signed up on SceneCore,
or who signed up but never got a `BandMembership` for that band — to ask
to be let in as that band's administrator. The only ways a
`BandMembership` gets created today are:

- the band's creator, at sign-up (`BandsController#create` makes them an
  `administrator` immediately);
- an existing Band Administrator inviting someone
  (`BandMembershipsController`);
- a Platform Administrator granting it directly
  (`Admin::PrivilegesController`).

None of these help someone who isn't already known to the band or the
platform. This proposal adds a fourth path: a message any signed-in user
can send from the band's page, asking the platform to let them in.

This is not described in `docs/permissions.md`, `docs/band-admin.md`,
`docs/memberships.md`, or `ROADMAP.md` — it is new capability.

## Decisions

1. **Who can send the request**: any signed-in user, from the band's
   page — not only someone who already holds a `BandMembership` for that
   band. An anonymous visitor must sign in first (this is not a public,
   unauthenticated form like Contact Us): the request needs a `User` to
   attach the resulting membership to if approved, and a real account is
   also the only real anti-abuse gate available.
2. **What it is**: a message to the platform, not an automatic grant. It
   carries no proof of who the person actually is — a Platform
   Administrator reviews it and uses their own judgment (contacting the
   person outside SceneCore if needed) before deciding.
3. **On approval**: creates a new `BandMembership` for that user on that
   band, with `role: administrator`. (If the user already happens to
   hold a `BandMembership` there — e.g. as a plain member — approval
   promotes that existing membership instead of creating a duplicate;
   `BandMembership` already enforces one membership per user per band.)
4. **On rejection**: no membership is created or changed. The user may
   send a new request later — rejection does not block resubmission.
5. **Revoking**: cancelling a still-*pending* request. The requester
   themselves, or a Platform Administrator, can do this. It never
   demotes or removes an already-granted membership — that is the
   existing `Admin::PrivilegesController` / a band administrator's own
   member-management path.
6. **Notification**: the requester is emailed when a Platform
   Administrator approves or rejects the request (see Implementation).
7. **One pending request per (user, band) pair** — a user can't stack a
   second request for the same band while one is still open.

## Authorization

- Creating a request: any signed-in user (`user.present?`), for
  themselves only.
- Revoking a pending request: the requester, or a Platform
  Administrator.
- Approving/rejecting: Platform Administrator only
  (`user.platform_admin?`), mirroring `BandPolicy#approve?`/`#reject?`.
- No band-scoped administrator gets visibility into these requests —
  this is a user-to-platform flow, reviewed only under `Admin::*`.

## Implementation plan

Reworks the `BandAdminRequest` model introduced for the earlier draft of
this proposal: it moves from `belongs_to :band_membership` (which
assumed the requester was already a member) to `belongs_to :user` +
`belongs_to :band` directly, since the requester usually has neither yet.

1. **Migration**: replace `band_admin_requests.band_membership_id` with
   `user_id` and `band_id` (both FK, indexed). Status enum unchanged
   (`pending`/`approved`/`rejected`/`revoked`), DB check constraint kept.
   Partial unique index moves to `(user_id, band_id)` where
   `status = 'pending'`.
2. **Model**: `BandAdminRequest` — `belongs_to :user`, `belongs_to :band`.
   Drops the "must already be a plain member" validation from the
   earlier draft (a requester usually isn't a member at all now).
3. **Policy**: `BandAdminRequestPolicy#create?` — any signed-in user.
   `revoke?` — the requester or a platform admin. `approve?`/`reject?` —
   platform admin only. (Unchanged in shape from the earlier draft,
   just no longer requires an existing membership.)
4. **Member-facing controller**: `BandAdminRequestsController` — `create`
   (from the band's page, any signed-in user) and `destroy`/revoke (the
   requester cancels their own pending request). No membership lookup
   needed on create now; `destroy` finds the current user's own pending
   request for that band.
5. **Admin-facing controller**: `Admin::BandAdminRequestsController` —
   `approve` finds-or-creates the `BandMembership` for
   `(band_admin_request.user, band_admin_request.band)` and sets
   `role: administrator` (reusing `BandMembership`'s own validations/
   invariants), then marks the request `approved`. `reject` marks
   `rejected`. `revoke` as before.
6. **Mailer**: unchanged in shape — `BandAdminRequestMailer` emails the
   user on approval/rejection, `deliver_later`, failure logged/captured
   without blocking the controller action (`ContactMessagesController`
   pattern).
7. **View**: the band's page shows "Request administrator access" to any
   signed-in user without a pending request for that band (previously
   gated to a plain Band Member only); "Withdraw request" once pending.
   Signed-out visitors see nothing here (or, if useful, a sign-in
   prompt) rather than the button.
8. **Admin view**: unchanged — `Admin::BandAdminRequestsController#index`
   lists requests; approve/reject buttons for pending ones. Display now
   shows the requesting user's name/band directly (no membership to
   route through).
9. **Tests**: update model/policy/request specs to reflect
   `user`+`band` instead of `band_membership`; add a case for a
   requester who already holds a plain membership (approval promotes it
   rather than creating a second one).

## Explicitly out of scope

- Demoting an existing administrator ("revoke" only ever cancels a
  *pending request*).
- Any verification of the requester's real-world identity/ownership of
  the band beyond what the Platform Administrator does manually.
- An in-app notification/inbox system — email only.

## Revision history

- Initial draft assumed the requester already held a `BandMembership`
  with `role: member` for the band, and modeled this as a promotion
  request. Implemented and opened as PR #196. Superseded once it became
  clear the actual need is someone with no existing tie to the band
  asking to be let in — a different shape of request, reworked above.
