# Community Coach — Implementation Plan

Open-source, self-hostable community + group-coaching subscription platform. Skool-class
feature set, AGPL, `docker compose up` on one VPS.

**Stack:** Rails 8 API + Next.js 15 App Router + PostgreSQL 17.
**v1 scope:** community feed, classroom/courses, paid memberships, live calls/calendar.
**Deferred to v2:** gamification, points, levels, leaderboards.

---

## 1. Architecture

### 1.1 Shape

```
                    ┌──────────────┐
   browser  ───────►│    Caddy     │  TLS, single origin
                    └──────┬───────┘
                           │
              /api/* /cable/* /rails/*      everything else
                           │                        │
                    ┌──────▼───────┐         ┌──────▼──────┐
                    │  Rails 8 API │         │  Next.js 15 │
                    │  Puma        │◄────────┤  RSC fetch  │
                    └──────┬───────┘  cookie └─────────────┘
                           │           forward
        ┌──────────────────┼──────────────────┐
        │                  │                  │
  ┌─────▼─────┐    ┌───────▼──────┐   ┌───────▼──────┐
  │ Postgres  │    │ Solid Queue  │   │ MinIO / S3   │
  │ (app +    │    │ worker       │   │ uploads,     │
  │  queue +  │    │ (ffmpeg,     │   │ HLS renditions│
  │  cable +  │    │  mail, drip) │   └──────────────┘
  │  cache)   │    └──────────────┘
  └───────────┘
```

**Why single origin matters:** Caddy fronts both apps on one hostname. The session cookie
is set by Rails as `__Host-session; Secure; HttpOnly; SameSite=Lax` and is therefore sent
to both the Next.js and Rails paths with no CORS, no JWT, no token refresh dance. Server
components forward the inbound `Cookie` header to Rails over the internal Docker network.
This is the single most important decision in the whole design — get it wrong and auth
becomes the project's permanent tax.

### 1.2 Why Rails 8 specifically

Rails 8 ships Solid Queue, Solid Cache and Solid Cable, all Postgres-backed. That removes
Redis from the dependency list entirely. A self-hoster's compose file is Postgres + MinIO +
three app containers. Fewer moving parts is a real adoption feature for an OSS project.

Trade-off to accept knowingly: Solid Cable polls Postgres rather than using a pub/sub
broker. Fine to a few thousand concurrent sockets per community. The adapter is swappable
(`config/cable.yml`) to Redis or AnyCable when a deployment outgrows it — document the
threshold rather than pre-optimizing.

### 1.3 Repo layout

```
community-coach/
├─ api/                          # Rails 8, API-only
│  ├─ app/
│  │  ├─ models/                 # ActiveRecord + concerns
│  │  ├─ controllers/api/v1/
│  │  ├─ serializers/            # Alba
│  │  ├─ policies/               # Pundit
│  │  ├─ services/               # domain ops (Billing::, Video::, Access::)
│  │  ├─ jobs/                   # Solid Queue
│  │  └─ mailers/
│  ├─ db/migrate/
│  ├─ config/
│  └─ spec/                      # RSpec: models, requests, jobs, policies
├─ web/                          # Next.js 15
│  ├─ app/
│  │  ├─ (public)/               # landing, about, checkout, auth
│  │  └─ (app)/                  # authed shell: feed, classroom, calendar, members
│  ├─ components/ui/             # shadcn/ui
│  ├─ lib/api/                   # generated typed client
│  └─ e2e/                       # Playwright
├─ packages/openapi/             # OpenAPI doc + generated TS types (build artifact)
├─ deploy/
│  ├─ docker-compose.yml         # the documented happy path
│  ├─ docker-compose.dev.yml
│  ├─ Caddyfile
│  └─ .env.example
├─ docs/
└─ .github/workflows/
```

Monorepo, no Nx/Turbo. Two runtimes with almost no shared code — a `Makefile` and pnpm
workspaces for `web/` + `packages/` is enough. Resist tooling that buys nothing here.

### 1.4 Contract between the two apps

Rails exposes versioned REST at `/api/v1`. Request specs are annotated with `rswag`, which
emits `packages/openapi/openapi.yaml` in CI. `openapi-typescript` turns that into
`lib/api/schema.d.ts`. A CI job fails the build if the committed schema drifts from what the
specs produce, so the frontend can never silently diverge from the API.

Serialization: Alba + Oj. Cursor pagination everywhere a list can grow unbounded
(feed, comments, members, notifications) — offset pagination on a feed sorted by
`last_activity_at` produces duplicates and gaps the moment anyone posts.

---

## 2. Multi-tenancy

One install hosts many communities. Skool's model, and the thing that makes this useful
beyond one coach.

- **Isolation:** shared database, `community_id` on every tenant-owned table.
- **Enforcement:** `acts_as_tenant`, with `Current.community` resolved in middleware from
  the request host (`{slug}.example.com`, or a verified custom domain row).
- **Safety net:** a RuboCop rule plus a spec that asserts every model inheriting from
  `ApplicationRecord` either declares `acts_as_tenant` or is on an explicit global allowlist
  (`User`, `Community`, `CustomDomain`, `AuditLog`). Tenancy bugs are silent data leaks;
  the test suite has to be the thing that catches them, not review.
- **Users are global.** One `User` (identity, email, password) can hold `Membership` rows in
  many communities. This is what enables the multi-community future and cross-community
  single sign-on.

Postgres RLS is deliberately not used in v1 — `acts_as_tenant` plus the guard spec gives
most of the protection at a fraction of the operational friction. Revisit if a hosted
multi-org offering ever ships.

---

## 3. Data model

Core tables. Types elided; every table gets `id bigint`, timestamps, and `community_id`
unless noted global.

### Identity and access

| Table | Notable columns |
|---|---|
| `users` *(global)* | `email_address` citext uniq, `password_digest`, `name`, `avatar`, `confirmed_at`, `totp_secret`, `locale`, `timezone` |
| `sessions` *(global)* | `user_id`, `token_digest`, `user_agent`, `ip`, `last_active_at`, `expires_at` |
| `communities` *(global)* | `slug` uniq, `name`, `privacy` enum(public,private,secret), `branding` jsonb, `settings` jsonb, `currency`, `billing_mode` |
| `custom_domains` *(global)* | `community_id`, `hostname` uniq, `verified_at`, `acme_state` |
| `memberships` | `user_id`, `community_id` uniq pair, `role` enum(owner,admin,moderator,member), `status` enum(pending,active,past_due,suspended,cancelled), `joined_at`, `last_seen_at`, `points` *(v2, nullable now)* |
| `invitations` | `email`, `role`, `token_digest`, `invited_by_id`, `accepted_at`, `expires_at` |
| `join_requests` | `user_id`, `answers` jsonb, `state`, `reviewed_by_id` |

Explicit session rows rather than opaque cookie-stored sessions: needed for "log out all
devices", session listing in security settings, and instant revocation on ban.

### Community feed

| Table | Notable columns |
|---|---|
| `categories` | `name`, `slug`, `position`, `access_rule` jsonb, `post_permission` enum(all,admins) |
| `posts` | `category_id`, `user_id`, `title`, `body` jsonb *(rich-text doc)*, `body_text` tsvector, `kind` enum(discussion,poll,announcement), `pinned_at`, `locked_at`, `comments_count`, `reactions_count`, `last_activity_at`, `deleted_at` |
| `comments` | `post_id`, `parent_id`, `user_id`, `body` jsonb, `path` ltree, `depth`, `reactions_count`, `deleted_at` |
| `reactions` | polymorphic `reactable`, `user_id`, `kind` — uniq (reactable, user, kind) |
| `polls` / `poll_options` / `poll_votes` | `post_id`, `closes_at`, `multiple` |
| `mentions` | polymorphic `source`, `mentioned_user_id` |
| `subscriptions` | polymorphic `subject`, `user_id`, `reason` enum(author,participant,manual,mention) |
| `reports` | polymorphic `subject`, `reporter_id`, `reason`, `state`, `resolved_by_id` |

Comment threading uses `ltree` on `path`. It gives ordered subtree fetches in one indexed
query, which the adjacency-list-plus-recursive-CTE alternative does not do cheaply at
depth. Cap `depth` at 5 in the model and flatten deeper replies, as Skool does.

`body` is stored as a rich-text JSON document (Tiptap/ProseMirror schema), not HTML.
Sanitizing at render is where XSS bugs live; storing a constrained document and rendering
from it server-side removes the class. `body_text` is a generated tsvector column for
search.

### Classroom

| Table | Notable columns |
|---|---|
| `courses` | `title`, `slug`, `description`, `cover`, `access_rule` jsonb, `published_at`, `position` |
| `course_modules` | `course_id`, `title`, `position` |
| `lessons` | `course_module_id`, `title`, `slug`, `body` jsonb, `video_asset_id`, `position`, `drip_kind` enum(none,days_after_join,fixed_date), `drip_days`, `drip_at`, `published_at` |
| `lesson_attachments` | Active Storage, plus `download_permitted` |
| `lesson_progress` | `user_id`, `lesson_id` uniq pair, `state` enum(unseen,started,completed), `seconds_watched`, `completed_at` |
| `video_assets` | `status` enum(uploading,processing,ready,failed), `provider` enum(local,mux,bunny,stream), `provider_ref`, `duration`, `renditions` jsonb, `thumbnail` |

`access_rule` jsonb is the single gate format shared by categories, courses and lessons:

```json
{ "type": "all_of",
  "rules": [ { "plan_in": ["pro","annual"] },
             { "min_level": 3 },
             { "drip_ready": true } ] }
```

One `Access::Resolver` service evaluates it for `(user, resource)`. `min_level` is a no-op
in v1 and lights up when gamification lands in v2 — the schema is ready, the code path
returns `true`.

### Calendar and live calls

| Table | Notable columns |
|---|---|
| `events` | `title`, `description`, `host_id`, `starts_at`, `duration_minutes`, `timezone`, `rrule`, `recurrence_end_at`, `location_kind` enum(zoom,meet,jitsi,url,in_person), `location_url`, `access_rule` jsonb, `cancelled_at` |
| `event_occurrences` | `event_id`, `starts_at`, `ends_at`, `overridden` bool, `cancelled_at` — materialized rows |
| `event_rsvps` | `event_occurrence_id`, `user_id`, `state` enum(going,maybe,declined), `reminded_at` |
| `recordings` | `event_occurrence_id`, `video_asset_id`, `published_at` |

Recurring events are stored as an RRULE **and** materialized into `event_occurrences` for a
rolling 12-month horizon by a recurring job. Querying "what's on the calendar this month"
against raw RRULEs across many events means expanding every rule on every request; the
materialized table makes it one indexed range scan. Per-occurrence overrides
(one session moved, one cancelled) fall out naturally.

Store `starts_at` as UTC plus a separate IANA `timezone` string. A weekly 9am call must
stay 9am local across DST — UTC-only storage silently shifts it by an hour twice a year.

### Billing

| Table | Notable columns |
|---|---|
| `plans` | `name`, `interval` enum(month,year,one_time), `amount_cents`, `currency`, `trial_days`, `provider_price_id`, `features` jsonb, `visible` |
| `subscriptions` | `membership_id`, `plan_id`, `provider_ref`, `status`, `current_period_end`, `trial_end`, `cancel_at_period_end`, `canceled_at` |
| `payments` | `subscription_id`, `amount_cents`, `status`, `provider_ref`, `invoice_url`, `paid_at` |
| `coupons` | `code`, `percent_off`/`amount_off`, `duration`, `max_redemptions`, `expires_at` |
| `webhook_events` | `provider`, `provider_event_id` uniq, `payload` jsonb, `processed_at`, `error` |

`webhook_events` with a unique index on `provider_event_id` is the idempotency spine.
Stripe retries, delivers out of order, and occasionally double-delivers. Every handler
reads the row, does its work in a transaction, stamps `processed_at`. Access is derived
from local `subscriptions` state only — never from a live API call in the request path.

### Notifications and messaging

| Table | Notable columns |
|---|---|
| `notifications` | `user_id`, `kind`, `actor_id`, polymorphic `subject`, `data` jsonb, `read_at`, `emailed_at` |
| `notification_preferences` | `user_id`, `community_id`, `kind`, `in_app`, `email` enum(off,instant,daily) |
| `push_subscriptions` | `user_id`, `endpoint`, `p256dh`, `auth` — Web Push VAPID |
| `conversations` / `conversation_participants` / `messages` | DMs — **v1.1** |
| `audit_logs` | `actor_id`, `action`, polymorphic `subject`, `changes` jsonb, `ip` |

---

## 4. Cross-cutting subsystems

### 4.1 Authentication

Rails 8's built-in auth generator as the base (`sessions`, `password_digest`, reset flow),
extended with:

- Email confirmation, password reset with single-use signed tokens
- TOTP 2FA + recovery codes for owner/admin roles (recommended, not forced, for members)
- OmniAuth for Google and (optionally) Apple — one `identities` table
- Session list + individual revoke in security settings
- `rack-attack` throttles on login, signup, password reset, invite acceptance

CSRF, given a cookie-authed API: no Rails form tokens. Instead every mutating request must
carry `Origin` matching the configured host, plus a `X-Requested-With` header the browser
will not attach cross-site without a preflight. Cookie is `SameSite=Lax`. This trio is the
standard cookie-API defense and is simpler to keep correct than token rotation.

### 4.2 Authorization

Pundit, with `after_action :verify_authorized` and `:verify_policy_scoped` enabled globally
in `Api::V1::BaseController` — no opt-in. A controller action that forgets authorization
raises in test and in production, rather than quietly serving data.

Two layers, kept distinct:
1. **Role** — can a moderator lock this post? (Pundit policy)
2. **Entitlement** — can this member *see* this course? (`Access::Resolver` against
   `access_rule` + subscription + drip)

Conflating them is how paywalls leak. Policies call the resolver; the resolver knows
nothing about roles.

### 4.3 Video pipeline

Pluggable `Video::Provider` interface, chosen by `VIDEO_PROVIDER` env.

- **`local` (default):** browser uploads directly to object storage via presigned PUT →
  `VideoAsset` created `status=uploading` → Solid Queue job runs ffmpeg to an HLS ladder
  (360p/720p/1080p, H.264 + AAC) → renditions uploaded → `status=ready`. Playback via
  hls.js against short-TTL signed URLs.
- **`mux` / `bunny` / `stream`:** direct-upload URL from the provider, webhook flips
  `status=ready`, playback uses signed provider playback IDs.

Be honest in the docs: local ffmpeg transcoding on a $20 VPS is slow and will contend with
web traffic. Ship the worker with a configurable concurrency of 1, a `nice` level, and a
docs page that says "for more than a handful of hours of video, use an external provider
or a dedicated worker host."

Video access control: playback URLs are signed, short-lived, and minted only after
`Access::Resolver` approves. Without that, a paywalled course is one shared URL away
from being free.

### 4.4 Payments

`Billing::Provider` interface with a Stripe implementation in v1 (Paddle/Lemon Squeezy are
the intended second implementations, and the interface exists so they are additive).

Two billing modes, both needed:

- **`direct`** *(self-host default)* — the community owner puts their own Stripe keys in the
  admin settings. Money goes straight to them. No platform, no fees, no KYC for the
  operator. This is the mode 95% of self-hosters want.
- **`connect`** — Stripe Connect Express, platform takes an application fee. For anyone
  running this as a multi-tenant hosted service.

Flows to build: checkout (Stripe Checkout hosted, not custom Elements — one fewer PCI
surface), trials, upgrade/downgrade with proration, cancel-at-period-end, dunning via
Stripe Smart Retries with `past_due` gating access after a grace period, customer portal
for payment-method updates, coupons, and tax via Stripe Tax as an opt-in flag.

### 4.5 Notifications

Fan-out on write into `notifications`, deduped per `(user, subject, kind)` within a window
so ten likes on one post produce one row that increments. Delivery:

- In-app: Action Cable push + unread badge
- Email: instant or rolled into a daily digest job, per-kind preference
- Web Push: VAPID, for mentions/DMs/event-starting-soon

Recurring jobs (Solid Queue `recurring.yml`): daily digest, event reminders at T-24h and
T-15m, drip unlock notices, trial-ending notices, weekly owner analytics summary.

### 4.6 Search

Postgres full-text in v1: generated `tsvector` columns, GIN indexes, `websearch_to_tsquery`,
`ts_rank_cd` with a recency decay. Covers posts, comments, lessons, members. A
`Search::Backend` seam exists so a Meilisearch adapter can be added without touching call
sites — but do not ship two backends in v1.

### 4.7 Realtime

Action Cable channels: `FeedChannel` (new posts/comments in a category), `PostChannel`
(live comments + reaction counts), `NotificationChannel`, `PresenceChannel` (online members).
Frontend uses `@rails/actioncable` wrapped in a React context, with TanStack Query cache
updates on message receipt rather than refetching.

---

## 5. Frontend plan

- Next.js 15 App Router, TypeScript strict, React Server Components for initial loads
- Tailwind + shadcn/ui as the component base; a `branding` jsonb per community maps to CSS
  custom properties so white-labeling is a theme swap, not a fork
- TanStack Query for all client-side mutation/refetch; RSC for first paint
- Tiptap editor for posts, comments and lessons, constrained to the stored document schema
- `next/image` with a Rails-side variant endpoint (Active Storage) — do not let Next.js
  optimize remote images at runtime on a small VPS
- Route groups: `(public)` for landing/about/checkout/auth, `(app)` for the authed shell
- Mobile-first; the community feed is a mobile surface first and a desktop one second

Testing: Vitest + Testing Library for component logic, Playwright for the flows that carry
money or access — signup → checkout → paywalled lesson, invite → join → post, event RSVP →
reminder.

---

## 6. Delivery milestones

Estimates assume one experienced full-time developer. Halve the calendar with two.

### M0 — Foundations (2 weeks)
Rails 8 API skeleton, Next.js skeleton, Caddy single-origin routing, docker-compose (dev +
prod), Postgres, MinIO, Mailpit. Auth end to end (signup, login, confirm, reset, sessions,
2FA). `Community` + `Membership` + `acts_as_tenant` with the guard spec. Pundit base
controller with forced verification. CI: RuboCop, Brakeman, RSpec, ESLint, tsc, Playwright
smoke, GHCR image build. Seeds that create a demo community with realistic data.

**Exit:** a stranger clones the repo, runs `docker compose up`, signs up, lands in an empty
community. That is the moment the project becomes real.

### M1 — Community feed (3 weeks)
Categories with permissions. Posts: rich text, images, video embeds, link previews, polls,
announcements. Threaded comments via ltree. Reactions. Pin/lock. Edit history. Full-text
search. Infinite feed with cursor pagination, sorted by `last_activity_at`. Action Cable
live updates. Mentions with autocomplete. Report → moderation queue. rack-attack rate
limits and a new-member post throttle.

### M2 — Members, notifications, moderation (2 weeks)
Member directory + profiles. Invitations, join requests with application questions,
approval queue. Role management. Suspend/ban with session revocation. Notification
subsystem end to end (in-app, email, digest, Web Push) with per-kind preferences. Audit log.

### M3 — Classroom (3 weeks)
Courses → modules → lessons with drag-reorder. Rich lesson bodies, attachments. Video
upload → HLS pipeline with the `local` provider, plus one external provider adapter to
prove the interface. Progress tracking with resume position. Drip scheduling (days-after-join
and fixed-date). `Access::Resolver` wired to `access_rule` on courses and lessons.
Course-completion certificates as a small delight feature.

### M4 — Billing and public pages (3 weeks)
Plans admin. Stripe Checkout, both `direct` and `connect` modes. Webhook ingestion with the
idempotency table. Trials, proration, cancel, dunning, `past_due` grace then gate. Coupons.
Member billing portal. Public community landing page (about, preview posts, pricing,
testimonials) — this is the sales surface and deserves real design attention. Free vs paid
community modes.

**Exit:** money moves, and a paywalled lesson is genuinely inaccessible to a free member —
including its video URL.

### M5 — Calendar and live calls (2 weeks)
Events with RRULE + materialized occurrences + per-occurrence overrides. Timezone-correct
display. RSVP. Zoom/Meet/Jitsi link fields, plus an optional Zoom OAuth integration that
creates meetings automatically. ICS feed subscription and per-event `.ics` download.
Reminder jobs. Recordings library that reuses the classroom video pipeline.

### M6 — Admin, branding, analytics (2 weeks)
Community settings, branding/theme editor, custom domain with automatic TLS through Caddy's
on-demand ACME. Owner analytics: MRR, churn, trial conversion, active members, post and
lesson engagement, retention cohorts. Data export (GDPR) and account deletion. Email
template customization.

### M7 — Hardening and 1.0 (2 weeks)
Load test the feed and video endpoints. N+1 sweep (`prosopite` in CI). Index review against
`pg_stat_statements`. Backup/restore runbook (`pg_dump` + object storage sync, and a
*tested* restore). Upgrade path: migrations on boot behind a Postgres advisory lock.
Security review, dependency audit, Trivy on images. Docs site: install, configure, upgrade,
back up, contribute. Demo instance. Launch.

**Total: ~19 weeks solo to a 1.0 worth self-hosting.**

### After 1.0
- **v1.1** — DMs and group chat (schema is already sketched above)
- **v2** — gamification: points, levels, leaderboards (7/30/all-time), badges, level-gated
  content. `min_level` in `access_rule` and `memberships.points` already exist for it.
- **v2+** — public REST API with scoped tokens, outbound webhooks, Zapier, affiliate
  program, mobile apps (React Native against the same API), plugin/extension system,
  AI-assisted moderation and course drafting, multi-language.

---

## 7. Operations

**Compose services:** `caddy`, `web` (Next.js), `api` (Puma), `worker` (Solid Queue),
`postgres`, `minio`. Dev adds `mailpit`. No Redis.

**Config:** one `.env`, documented in `.env.example`, validated at boot by a
`Config` object that fails loudly on a missing required key rather than 500-ing on first
use. Secrets never in the image.

**Observability:** structured JSON logs, `/up` and `/health/ready` endpoints,
OpenTelemetry traces behind a flag, optional Sentry DSN. Ship a Grafana dashboard JSON as a
docs extra, not a required container.

**Backups:** a documented cron running `pg_dump` plus object-storage sync, and a restore
script. An untested restore is not a backup — M7 includes actually running it.

**Upgrades:** semver on the images, migrations run on boot under an advisory lock so a
multi-replica deploy cannot race, and a `docs/UPGRADING.md` with per-minor notes.

**Resource floor to publish:** 2 vCPU / 4 GB for a community up to ~1k members with
external video. Note that local transcoding changes that number substantially.

---

## 8. Project decisions

**License: AGPL-3.0.** The product's natural competitor is a hosted SaaS. AGPL keeps a
closed hosted fork from taking the work without contributing back, while leaving every
self-hoster completely free. Pair it with a CLA if a commercial license is ever wanted;
otherwise DCO sign-off is lighter and friendlier to contributors.

**Contribution surface:** `CONTRIBUTING.md`, a `docs/ARCHITECTURE.md` that stays honest,
`good-first-issue` labels, and a devcontainer so a contributor is productive in one command.
The tenancy guard spec and forced Pundit verification exist partly so that outside
contributions cannot introduce the two scariest bug classes by accident.

**Deliberate non-goals for 1.0:** native mobile apps, live-streaming inside the platform
(link out to Zoom/Meet), an email marketing suite, a course marketplace, plugin
architecture, and horizontal autoscaling. Each is defensible later; none belongs in a 1.0
that has to be installable in one command.

---

## 9. The risks worth naming now

| Risk | Mitigation |
|---|---|
| Video transcoding sinks a small VPS | External provider adapters shipped in M3, honest docs, isolated worker with capped concurrency |
| Paywall leaks via direct asset URLs | Signed short-TTL URLs minted only after `Access::Resolver`; a Playwright test that asserts a free member gets 403 on a paid lesson's video |
| Tenancy leak | `acts_as_tenant` + allowlist guard spec + policy scoping forced at the base controller |
| Stripe webhook duplication/reordering | `webhook_events` idempotency table, local-state-only entitlement |
| Two-runtime auth complexity | Single-origin cookie via Caddy — the design in §1.1 exists specifically to defuse this |
| Solid Cable ceiling on realtime | Documented threshold and a one-line adapter swap to Redis/AnyCable |
| Scope creep past 1.0 cut-line | §8 non-goals list, and gamification already explicitly deferred to v2 |
