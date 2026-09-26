# SceneCore Media Storage and Video Roadmap

This document records the implementation plan for Complete Demos, hosted
videos, and exclusive streams so the work can be paused and resumed safely.

## Current checkpoint

As of 2026-09-26:

- Production attachments are stored by Active Storage on the Railway
  persistent volume configured through `ACTIVE_STORAGE_PATH`.
- MP3, WAV, and PDF post attachments are supported, with a 25 MB limit.
- Attachment downloads are routed through authenticated SceneCore endpoints.
- Posts already enforce the Public, Fan, Supporter, and Core Member hierarchy.
- Exclusive sessions support external access URLs, capacity, and RSVP.
- Complete Demos, Exclusive Videos, and Exclusive Streams are displayed as
  `In development`.
- No Cloudflare R2 bucket has been confirmed as created yet.
- No R2, Mux, or native live-streaming credentials are configured.
- The Railway volume remains the source of truth and must not be removed.

Resume at **Step 1 — Create the private R2 bucket**.

## Progress register

Allowed statuses:

- `Not started`: no confirmed external or code change.
- `In progress`: work started but its checkpoint has not passed.
- `Blocked`: a named dependency prevents progress.
- `Validated`: the step's checkpoint and evidence passed.
- `Rolled back`: the step was reversed and the previous path was restored.

### Step 1 — Private R2 bucket

- Status: `Not started`
- Started: —
- Validated: —
- Owner: SceneCore
- Evidence: —
- Decision notes: Proposed bucket name is `scenecore-production`.
- Rollback state: Railway volume remains the source of truth.

### Step 2 — CORS and restricted credentials

- Status: `Not started`
- Started: —
- Validated: —
- Owner: SceneCore
- Evidence: —
- Decision notes: Token must be limited to Object Read & Write on the production bucket.
- Rollback state: Revoke the token and remove the CORS policy.

### Step 3 — R2 Active Storage service

- Status: `Not started`
- Started: —
- Validated: —
- Owner: SceneCore application
- Evidence: —
- Decision notes: Add R2 before changing the active production service.
- Rollback state: Existing Railway disk service remains configured.

### Step 4 — Authenticated direct uploads

- Status: `Not started`
- Started: —
- Validated: —
- Owner: SceneCore application
- Evidence: —
- Decision notes: Upload bytes must travel directly from the browser to R2.
- Rollback state: Existing authenticated attachment upload remains available.

### Step 5 — Protected file access

- Status: `Not started`
- Started: —
- Validated: —
- Owner: SceneCore authorization
- Evidence: —
- Decision notes: Post visibility remains the source of truth.
- Rollback state: Do not enable public bucket access; retain existing protected routes.

### Step 6 — Copy Railway files to R2

- Status: `Not started`
- Started: —
- Validated: —
- Owner: SceneCore operations
- Evidence: —
- Decision notes: Copy only; never move or delete source files during this step.
- Rollback state: Railway files remain intact and authoritative.

### Step 7 — Migration integrity verification

- Status: `Not started`
- Started: —
- Validated: —
- Owner: SceneCore operations
- Evidence: —
- Decision notes: Verify count, keys, sizes, checksums, and protected downloads.
- Rollback state: Keep production reads on the Railway volume if verification fails.

### Step 8 — Expanded audio support

- Status: `Not started`
- Started: —
- Validated: —
- Owner: SceneCore product and application
- Evidence: —
- Decision notes: Start with playback-ready MP3 and M4A/AAC; approve limits before coding.
- Rollback state: Retain the existing MP3/WAV/PDF validation and 25 MB limit.

### Step 9 — Complete Demo content

- Status: `Not started`
- Started: —
- Validated: —
- Owner: SceneCore product and application
- Evidence: —
- Decision notes: Reuse Post and the Exclusive Feed instead of creating another feed.
- Rollback state: Keep the feature labeled `In development` until validated.

### Step 10 — Supporter access enforcement

- Status: `Not started`
- Started: —
- Validated: —
- Owner: SceneCore authorization
- Evidence: —
- Decision notes: Active Supporter and Core Member access; Fan access denied.
- Rollback state: Do not advertise Complete Demos as available before access tests pass.

### Step 11 — Band quotas and usage

- Status: `Not started`
- Started: —
- Validated: —
- Owner: SceneCore product, billing, and operations
- Evidence: —
- Decision notes: Block new uploads at the limit; no automatic overage in the MVP.
- Rollback state: Disable new media uploads without deleting stored media.

### Step 12 — Mux video integration

- Status: `Not started`
- Started: —
- Validated: —
- Owner: SceneCore application and operations
- Evidence: —
- Decision notes: Provider-neutral VideoAsset; Mux is the initial adapter.
- Rollback state: Keep video benefits labeled `In development` and retain external stream links.

## Execution log

Append one entry whenever a step starts, changes status, passes validation, or
is rolled back. Never record secrets.

Use this format:

```text
Date and time:
Step:
Previous status:
New status:
Actor:
Change performed:
Evidence:
Decision or exception:
Rollback performed or available:
Next action:
```

No execution entries have been recorded yet.

## Product ownership

SceneCore owns and operates the infrastructure integrations. Bands use them
through Band Admin and do not create their own R2 or Mux accounts.

Recommended ownership:

```text
SceneCore account
├── Cloudflare R2: audio, images, PDFs, and general attachments
└── Mux: processed on-demand video and, later, native live video
```

Every media record remains associated with its band. A Band Administrator can
manage only that band's media. Platform administration remains separate from
Fan, Supporter, and Core Member benefits.

## Membership access

The existing membership hierarchy remains authoritative:

```text
Fan media
→ Fan, Supporter, Core Member

Supporter media
→ Supporter, Core Member

Core Member media
→ Core Member only
```

Suggested product mapping:

- Fan: short behind-the-scenes videos.
- Supporter: Complete Demos, exclusive recorded videos, and exclusive streams.
- Core Member: private lives, Q&A, listening parties, meet-and-greets, rare
  recordings, and replays of Core sessions.

The band chooses the minimum audience for each post. The storage provider must
never become an alternative authorization source.

## Target architecture

```text
Band Admin requests upload
        ↓
SceneCore authorizes band, file, and quota
        ↓
Browser uploads directly to R2 or Mux
        ↓
Provider stores or processes the asset
        ↓
SceneCore stores metadata and provider identifiers
        ↓
Member requests playback
        ↓
SceneCore checks Post#visible_to?
        ↓
Short-lived signed playback access is issued
```

Files must not be stored in browser `localStorage`. Large uploads should not
pass through the Rails process. PostgreSQL stores metadata and relationships,
not media bytes.

## Detailed hosted video implementation

This section records the complete technical design for hosted video. It is a
design reference, while the later implementation order controls when each
piece may be introduced.

### 1. New video model

Create a provider-neutral `VideoAsset` associated with a Post. The Post owns
publication status, content type, band, and membership visibility. The video
record owns only provider and processing information.

Initial relationships:

```text
Band
└── Post
    └── VideoAsset
```

Suggested fields:

```text
post_id                 required foreign key
provider                mux initially
provider_upload_id      direct-upload identifier
provider_asset_id       processed asset identifier
playback_id             provider playback identifier
status                  processing lifecycle
duration_seconds        provider-confirmed duration
aspect_ratio            width/height or provider representation
thumbnail_url           generated thumbnail reference
error_code              stable machine-readable failure
error_message           safe operational explanation
ready_at                 when playback became available
deleted_at               optional provider-deletion marker
created_at
updated_at
```

Do not duplicate `band_id` or visibility unless a measured query requirement
justifies it. They are already reachable through the Post, and duplication
would create consistency risks.

Suggested lifecycle:

```text
pending → uploading → processing → ready
                     ↘ failed
ready → deleting → deleted
```

Required invariants:

- one video belongs to one Post;
- provider asset identifiers are unique within a provider;
- only `ready` assets are playable;
- a published post must not present an incomplete asset as playable;
- failed assets remain diagnosable and retryable;
- provider deletion is observable rather than silently assumed.

Migration strategy: add the model without changing current Post attachments.
Existing content remains readable throughout the rollout.

### 2. Provider-neutral integration layer

Controllers and models must not call the Mux SDK directly. Define an internal
contract so SceneCore can add Cloudflare Stream or replace providers without
rewriting authorization and product behavior.

Suggested interface:

```text
VideoProvider.create_direct_upload(video_asset:, constraints:)
VideoProvider.fetch_asset(provider_asset_id:)
VideoProvider.issue_playback_token(playback_id:, expires_at:)
VideoProvider.delete_asset(provider_asset_id:)
VideoProvider.verify_webhook(payload:, signature:)
VideoProvider.parse_webhook(event:)
```

Initial implementation:

```text
VideoProvider
└── MuxVideoProvider
```

Future-compatible implementation:

```text
VideoProvider
├── MuxVideoProvider
└── CloudflareStreamVideoProvider
```

Provider credentials belong to SceneCore and must remain in production secret
storage. Bands never supply or see provider API keys.

Tests should use a fake provider implementing the same contract. Request and
model tests must not depend on live provider calls.

### 3. Band upload experience

Extend the Band Admin Post form with a hosted-video option. The administrator
provides:

- title and description;
- video file;
- video content type;
- minimum audience: Fan, Supporter, or Core Member;
- publish now, save draft, or schedule where supported;
- optional custom cover;
- comments enabled or disabled if that product control is introduced.

Suggested video content types:

- behind-the-scenes short video;
- exclusive video;
- rehearsal video;
- making of;
- private session replay;
- rare archive.

Before creating an upload, SceneCore validates:

- the user is an administrator of that band or a Platform Administrator;
- the band is approved and allowed to publish;
- the video add-on or entitlement is active;
- storage and delivery limits permit a new upload;
- MIME type, file size, and declared duration are allowed;
- the chosen visibility is permitted for that content type;
- rate limits have not been exceeded.

Client-provided MIME type, size, and duration are advisory. Provider-confirmed
metadata becomes authoritative after processing.

### 4. Direct upload creation

The browser must upload directly to Mux instead of proxying the file through
Rails.

```text
Browser → SceneCore: request upload authorization
SceneCore → Mux: create one-time direct upload
Mux → SceneCore: upload URL and upload ID
SceneCore → Browser: temporary upload URL
Browser → Mux: video bytes
```

Suggested endpoint:

```text
POST /bands/:band_id/video_uploads
```

The endpoint should:

1. authorize the band;
2. validate requested constraints;
3. create a draft Post if the UI requires it;
4. create a pending VideoAsset;
5. request a signed, expiring, one-time provider upload URL;
6. persist the provider upload ID;
7. return only safe client fields.

The response may include:

```json
{
  "video_asset_id": 123,
  "upload_url": "provider-generated-temporary-url",
  "expires_at": "timestamp"
}
```

The UI should show progress, cancellation, and retry behavior. Abandoned
pending uploads need periodic cleanup without deleting assets that have
already reached the provider.

### 5. Provider processing and webhooks

After upload, the asset is not immediately playable. Mux validates and
transcodes it, generates adaptive renditions and thumbnails, and prepares the
playback asset.

Suggested endpoint:

```text
POST /video/webhooks/mux
```

The webhook endpoint must:

- skip browser session authentication and CSRF only for that endpoint;
- read the raw request payload;
- verify the provider signature before parsing or mutating state;
- persist a unique provider event ID;
- process repeated events idempotently;
- reject invalid signatures;
- return a successful response for already processed valid events;
- make partial processing failures observable and retryable.

Relevant events update the VideoAsset:

```text
upload completed     → processing
asset ready          → ready + playback metadata
asset errored        → failed + safe error details
asset deleted        → deleted
```

SceneCore should reconcile provider state periodically or on demand so a lost
webhook cannot leave a valid upload permanently stuck in `processing`.

### 6. Publication workflow

The safest first version saves the Post as a draft while video processing is
underway.

The Band Admin sees:

```text
Uploading…
Processing video…
Ready to review
Processing failed
```

When ready, the administrator can:

- preview playback;
- confirm title, description, visibility, and thumbnail;
- publish the Post;
- replace the failed or incorrect upload;
- delete the draft.

An optional `Publish automatically when ready` control may be added later. It
should not be the first default because processing can reveal incorrect files,
unexpected duration, orientation, or quality.

Publication remains a SceneCore state change. A provider-ready video does not
automatically become public or member-visible.

### 7. Membership access control

Reuse the existing `Post#visible_to?` hierarchy:

```text
Fan video       → Fan, Supporter, Core Member
Supporter video → Supporter, Core Member
Core video      → Core Member only
```

Playback authorization must verify:

1. the band is approved;
2. the Post exists and is published;
3. the VideoAsset belongs to that Post;
4. the VideoAsset is `ready`;
5. `post.visible_to?(current_user)` succeeds;
6. the relevant membership remains active;
7. neither the content nor provider asset has been deleted.

Never authorize playback from a `playback_id` alone. Never rely only on hiding
the player in the view. Paused, cancelled, and expired memberships must stop
receiving new playback tokens.

### 8. Secure playback tokens

Use signed provider playback rather than a permanent public URL.

Suggested endpoint:

```text
POST /videos/:id/playback_token
```

After authorization, SceneCore issues a short-lived token containing the
provider-required claims. The expiration must be long enough to finish the
video plus a small margin, without remaining reusable indefinitely.

The provider signing private key remains server-side. The browser receives
only the final temporary playback URL or token.

Additional restrictions may include:

- allowed SceneCore domain/referrer;
- playback-only permission;
- token expiration;
- non-personal internal session correlation for abuse investigation.

Do not put names, email addresses, membership details, or other personal data
inside provider token metadata.

Signed playback prevents simple link sharing and third-party embedding. It
does not prevent screen recording; DRM is a separate, more expensive product
decision and is not required for the MVP.

### 9. SceneCore player

Render the provider's supported HLS player or compatible SceneCore component
inside the Post.

Initial controls:

- play and pause;
- volume;
- seek bar;
- fullscreen;
- adaptive quality;
- thumbnail/poster;
- loading and error states;
- captions only when explicitly supported later.

Cost controls:

- no autoplay;
- no automatic loop;
- do not preload the complete video;
- show the poster before requesting playback;
- request the signed token only after a deliberate playback action;
- pause media when navigating away;
- avoid rendering active players for every off-screen feed item.

Accessibility requirements include keyboard controls, visible focus, player
labels, and a future path for captions/transcripts.

### 10. Limits by video type

Initial product constraints should be explicit and server-enforced.

Behind-the-scenes short videos:

- maximum 60–90 seconds;
- vertical or horizontal orientation;
- maximum 1080p;
- displayed inside the existing Exclusive Feed;
- no TikTok/Reels-style infinite feed in the MVP.

Exclusive recorded videos:

- initial maximum 15–30 minutes;
- usually Supporter or Core Member content;
- examples: making of, studio footage, interviews, recorded sessions.

Rare archives:

- normally Core Member content;
- longer limits only when the band's quota allows;
- examples: old recordings and unreleased material.

Provider-confirmed duration must be checked again after upload. Assets that
exceed the authorized limit must not become publishable merely because the
client declared a shorter duration.

### 11. Band quotas and consumption

Add a media entitlement owned by SceneCore, not Mux. Suggested limits:

```text
stored video minutes
monthly delivered minutes
maximum duration per asset
maximum short-video duration
maximum concurrent pending uploads
native live enabled or disabled
```

Band Admin should show current usage and the measurement period:

```text
Stored video: 43 / 60 minutes
Playback this month: 720 / 1,000 minutes
```

Threshold behavior:

- 70%: informational warning;
- 90%: prominent warning;
- 100%: block new uploads or require an approved upgrade;
- no automatic usage overage in the MVP.

Provider analytics and SceneCore records must be reconciled. Quota checks must
reserve declared duration for pending direct uploads so many concurrent uploads
cannot exceed the allowance before processing finishes.

### 12. Video deletion lifecycle

Deleting a Post and deleting a provider asset are related but separate
operations.

Safe sequence:

1. require confirmation from an authorized band administrator;
2. unpublish or make the Post unavailable;
3. mark the VideoAsset as `deleting`;
4. request deletion from the provider;
5. receive or reconcile provider confirmation;
6. mark the asset `deleted`;
7. release quota according to provider billing behavior;
8. retain only the operational record required for audit and troubleshooting.

Provider deletion failures must be retryable. SceneCore must not claim storage
was released until the provider confirms it. Destructive bulk deletion needs a
separate explicit operation and audit trail.

### 13. SceneCore Video billing model

The Mux account and provider bill belong to SceneCore. Bands purchase a
predictable SceneCore add-on rather than receiving raw provider charges.

Possible product layers:

```text
No video add-on
→ external links and existing external session URLs

SceneCore Video
→ hosted short and recorded videos
→ included storage and monthly playback allowance

SceneCore Live, later
→ native live hours and concurrent-viewer allowance
```

The add-on price must cover provider usage, application development, support,
monitoring, taxes, payment fees, and a safety margin. Fans should not be charged
per play.

Initial commercial behavior:

- show usage transparently;
- warn before limits;
- require band approval for upgrades;
- do not generate surprise overage invoices;
- keep external stream links as the low-cost fallback.

### 14. Complete Demos are a separate implementation

Complete Demos are audio and do not require Mux or video transcoding. They
should be implemented first using private object storage through Active
Storage and Cloudflare R2.

Initial architecture:

```text
Browser → authenticated direct upload → private R2 bucket
Post and metadata → PostgreSQL
Playback request → SceneCore authorization → temporary protected access
```

Initial formats:

- MP3;
- M4A/AAC;
- WAV retained only if limits permit;
- FLAC considered later.

Initial product behavior:

- reuse the existing Exclusive Feed and Post model;
- add the `complete_demo` post type;
- normally require Supporter, inherited by Core Member;
- render a protected HTML audio player;
- disable downloads by default;
- define file-size and duration limits;
- add band storage quotas before unrestricted use.

The current attachment implementation accepts MP3 and WAV with a 25 MB limit
and stores production files on the Railway volume. The R2 migration must be
completed and protected access verified before increasing the limit for broad
production use.

Later audio enhancements may include source WAV/FLAC upload, asynchronous AAC
or MP3 conversion, waveform generation, duration extraction, loudness
normalization, and band-controlled downloads. These must not block the first
playback-ready MP3/M4A version.

## Implementation order

### Step 1 — Create the private R2 bucket

Cloudflare Dashboard path:

```text
Storage & databases → R2 Object Storage → Create bucket
```

Initial configuration:

- Bucket name: `scenecore-production`
- Location: Automatic
- Storage class: Standard
- Public `r2.dev` access: disabled
- Custom domain: not configured
- Data Catalog: disabled
- Bucket Lock: not required during migration

Record the non-secret values:

- bucket name;
- Cloudflare Account ID;
- S3 endpoint, normally
  `https://ACCOUNT_ID.r2.cloudflarestorage.com`.

Do not store secrets in this document, Git, chat, screenshots, or application
source code.

Checkpoint:

```text
Bucket created: scenecore-production
Public access: disabled
Storage class: Standard
```

Rollback: delete the empty bucket if the project does not proceed. Do not
delete a bucket after uploads begin without a separately verified backup.

### Step 2 — Configure CORS and restricted credentials

Create an R2 API token with:

- Object Read & Write permission;
- access limited to `scenecore-production`;
- no account-wide administrative permission.

Capture the Access Key ID and Secret Access Key once. Store them in Railway
secrets and local Rails credentials or environment variables. Never commit
them.

Configure CORS only for the real SceneCore production origin and the required
HTTP methods for Active Storage direct uploads. Do not use unrestricted origins
in production.

Verification:

- credentials can list/write/read only the intended bucket;
- credentials cannot administer or delete unrelated buckets;
- a browser request from an unapproved origin is rejected.

Rollback: revoke the token and remove the CORS policy. The Railway volume is
unchanged.

### Step 3 — Add R2 as an Active Storage production service

Use the S3-compatible Active Storage adapter with the R2 endpoint. Expected
configuration inputs:

- access key ID;
- secret access key;
- bucket name;
- R2 S3 endpoint;
- region `auto`.

Do not immediately replace the production service. Add the configuration and
verify connectivity first. Keep the existing disk service available as the
rollback path.

Verification:

- application boot succeeds without printing secrets;
- a test object can be written, read, and deleted;
- the bucket remains private;
- signed access expires as expected.

### Step 4 — Implement authenticated direct uploads

Reuse the authenticated direct-upload pattern already used by posts:

1. Band Admin requests an upload URL.
2. SceneCore verifies the band relationship and file metadata.
3. Active Storage creates a pending blob.
4. The browser sends the file directly to R2.
5. The blob is attached only to a record the administrator may manage.

Required controls:

- authentication;
- Band Administrator authorization;
- allowed content types;
- maximum file size and duration where available;
- rate limiting;
- checksum verification;
- cleanup of abandoned unattached blobs.

### Step 5 — Preserve protected file access

Keep the existing server-side authorization semantics. Knowing a blob key or
attachment identifier must not grant access.

Verification matrix:

- signed-out visitor cannot fetch member-only audio;
- Fan cannot fetch Supporter audio;
- Supporter can fetch Fan and Supporter audio;
- Core Member can fetch all three levels;
- paused, cancelled, and expired memberships cannot fetch protected audio;
- one band's administrator cannot fetch another band's private attachments;
- generated URLs expire.

### Step 6 — Migrate existing files from Railway to R2

Use a retryable, idempotent migration task. Copy objects without changing the
Active Storage blob keys so database attachment references remain valid.

Migration stages:

1. Inventory existing blobs and total bytes.
2. Take a recoverable backup or snapshot of the Railway volume.
3. Copy objects to R2 without deleting the source.
4. Record success and failure per blob key.
5. Retry only failed or missing objects.
6. Keep both copies throughout the compatibility window.

Do not use a move operation. Do not remove source files in this step.

### Step 7 — Verify migration integrity

Compare:

- expected blob count;
- copied object count;
- object key equality;
- byte size;
- checksum where supported;
- representative protected downloads for each membership level;
- images, MP3, WAV, and PDF files;
- zero-byte and missing-object reports.

Only after verification should new production uploads switch to R2. The old
volume must remain available for an agreed observation window. Removing it is a
separate destructive action requiring explicit authorization.

### Step 8 — Expand audio support

Complete Demos should initially accept playback-friendly formats:

- MP3;
- M4A/AAC;
- optionally WAV and FLAC as source formats later.

The first version should not promise automatic conversion. Prefer a documented
duration and file-size limit and require a playback-ready upload. Revisit the
current 25 MB limit based on the chosen maximum demo duration and bitrate.

Later enhancements may include:

- WAV/FLAC transcoding;
- normalized playback volume;
- waveform generation;
- automatic duration and metadata extraction;
- preservation or removal of the original source file;
- band-controlled downloads.

### Step 9 — Implement Complete Demo content

Use the existing Post model and membership visibility instead of creating a
second feed.

The Band Admin experience should support:

- content type `complete_demo`;
- title and description;
- one or more protected audio tracks;
- Supporter as the normal minimum audience;
- draft and published states;
- an embedded audio player in the Exclusive Feed.

Do not infer that every demo must be Supporter-only. The band's explicit
visibility selection remains authoritative, subject to product rules.

### Step 10 — Enforce Supporter access

Complete Demos advertised as a Supporter benefit must be available to active
Supporters and Core Members, not Fans. Enforce this in the model/policy and
protected blob endpoint, not only in the view.

Add regression tests for content listing, direct attachment access, membership
status changes, hierarchy inheritance, and cross-band isolation.

### Step 11 — Add quotas and usage per band

Introduce explicit entitlements before allowing unrestricted uploads:

- total stored bytes or minutes;
- maximum file size;
- maximum duration;
- monthly upload allowance;
- warning thresholds at 70%, 90%, and 100%;
- behavior at the limit, initially blocking new uploads rather than charging
  an automatic overage.

Expose usage in Band Admin. SceneCore should own the provider bill and offer a
predictable media add-on to bands. Fans should not be charged per playback.

### Step 12 — Integrate Mux for video

Add a provider-neutral `VideoAsset` associated with a draft Post. Suggested
fields:

```text
post_id
provider
provider_upload_id
provider_asset_id
playback_id
status
duration_seconds
aspect_ratio
thumbnail_url
error_message
ready_at
```

Suggested statuses:

```text
pending → uploading → processing → ready
                                 ↘ failed
ready → deleted
```

Create a provider interface rather than calling Mux directly from controllers:

```text
VideoProvider.create_upload
VideoProvider.asset_details
VideoProvider.playback_token
VideoProvider.delete_asset
VideoProvider.verify_webhook
```

The browser uploads directly to Mux. Signed, idempotent webhooks update asset
status. Playback requires a short-lived signed token issued only after
`Post#visible_to?` succeeds.

Initial limits:

- short behind-the-scenes videos: 60–90 seconds;
- recorded exclusive videos: 15–30 minutes;
- up to 1080p;
- no autoplay;
- no automatic looping;
- no native live streaming in the first video release.

## Exclusive streams and live video

Keep the existing external access URL flow during the first phases. Bands can
schedule Supporter or Core Member sessions, collect RSVP, and provide a private
Zoom, Meet, Vimeo, YouTube, or similar link.

Native live streaming is a later paid add-on because cost grows with stream
duration and concurrent viewing. A later `SceneCore Live` increment may add:

- stream keys and OBS integration;
- signed member playback;
- concurrent-viewer controls;
- recording and replay;
- purchased hour packages;
- real-time cost and usage monitoring.

## Cost controls

- Use private buckets and signed access.
- Upload directly from browser to provider.
- Do not autoplay or preload full media.
- Limit duration, size, and resolution.
- Give each band a visible quota.
- Alert before limits are reached.
- Block additional uploads instead of creating surprise overage charges.
- Delete provider assets when deletion is confirmed, while retaining required
  operational records.
- Keep Complete Demos on object storage and processed video on Mux.

## Safety and rollback rules

- Never delete Railway files during copy or verification.
- Never make the R2 bucket public to work around authorization problems.
- Never commit provider credentials.
- Never switch production storage before representative protected downloads
  pass.
- Never remove the Railway volume without explicit approval, a verified copy,
  and an observation window.
- Make migration tasks idempotent and safe to resume.
- Treat source cleanup as a separate final contraction phase.

## Completion checklist

- [ ] Step 1: private R2 bucket created.
- [ ] Step 2: restricted token and CORS configured.
- [ ] Step 3: R2 Active Storage service configured and connected.
- [ ] Step 4: authenticated direct uploads verified.
- [ ] Step 5: protected access regression tests pass.
- [ ] Step 6: existing files copied without source deletion.
- [ ] Step 7: count, size, checksum, and access verification pass.
- [ ] Step 8: playback-friendly audio formats and limits approved.
- [ ] Step 9: Complete Demo content implemented.
- [ ] Step 10: Supporter/Core access enforced and tested.
- [ ] Step 11: band quotas and usage dashboard implemented.
- [ ] Step 12: Mux video integration implemented.
- [ ] Observation window completed.
- [ ] Railway volume removal separately approved, if still desired.
