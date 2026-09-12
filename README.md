# Community Coach

An open-source community and group-coaching platform you can host yourself. Discussion
feed, course library, live calls and paid memberships, under your own brand and on your
own domain.

Rails 8 API · Next.js 15 · PostgreSQL 17 · AGPL-3.0

---

## Run it

```bash
cp deploy/.env.example deploy/.env      # set APP_HOST, POSTGRES_PASSWORD, SECRET_KEY_BASE
docker compose -f deploy/docker-compose.yml up -d
```

Five containers, no Redis — Rails 8's Solid Queue, Cache and Cable all run on Postgres, so
there is one datastore to operate and one thing to back up.

### Develop

```bash
# API
cd api && bundle install && bin/rails db:prepare db:seed && bin/rails server -p 3001

# Web
cd web && npm install && API_INTERNAL_URL=http://localhost:3001 npm run dev
```

Seeds create a demo community. Sign in as `sara@example.com` / `correct-horse-battery`.

---

## How it fits together

```
                    ┌──────────────┐
   browser  ───────►│    Caddy     │   one hostname, one cookie
                    └──────┬───────┘
          /api /auth /cable│  everything else
                    ┌──────▼───────┐         ┌─────────────┐
                    │  Rails 8 API │◄────────┤  Next.js 15 │
                    └──────┬───────┘ cookie  └─────────────┘
                           │         forwarded
        ┌──────────────────┼──────────────────┐
   ┌────▼────┐      ┌──────▼──────┐    ┌──────▼──────┐
   │Postgres │      │ Solid Queue │    │  S3 / MinIO │
   └─────────┘      └─────────────┘    └─────────────┘
```

**Single origin is the load-bearing decision.** Caddy fronts both apps on one hostname, so
the session cookie reaches both and server components forward it straight to Rails. No JWT,
no refresh rotation, no CORS. Get this wrong and auth becomes a permanent tax.

**Multi-tenant.** One install hosts many communities. Users are global; `Membership` joins
them to communities. Every tenant-owned table carries `community_id` and declares
`acts_as_tenant`, and `spec/models/tenancy_spec.rb` fails the build if a model forgets —
a missed tenant scope is a silent cross-community leak, not a loud error.

**Roles and entitlement are separate.** Pundit answers "may a moderator lock this post".
`Access::Resolver` answers "does their plan and drip schedule include this lesson".
Conflating them is how paywalls leak, so they are different objects with different tests.

**One palette.** Light only, deliberately. A token has one value and a component has one
appearance, so there is no second theme to keep legible on every change.

---

## Documentation

| | |
|---|---|
| [Implementation plan](docs/IMPLEMENTATION_PLAN.md) | Architecture, data model, milestones |
| [Design system](docs/DESIGN_SYSTEM.md) | Token layers, directions vs themes |
| [Whitelabeling](docs/WHITELABELING.md) | What owners control and why it cannot break |

Preview the design without running anything:

```bash
python3 -m http.server 8919
open http://127.0.0.1:8919/preview/index.html
```

---

## Whitelabel

A community owner changes fourteen values in admin settings — accent, neutral, three fonts,
radius, density, type scale, logo, domain — and the whole interface follows. No rebuild, no
deploy, no code.

`Branding::TokenCompiler` validates and compiles those into CSS custom properties. It will
not let an owner ship an unreadable interface: `Branding::Contrast` computes real WCAG
luminance, picks whichever of white or near-black actually wins on their accent rather than
assuming white, and walks the accent's lightness until it clears AA if neither does. They
keep their hue; their members keep a legible button.

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Three rules are enforced by tests rather than
review — tenant scoping, the token contract, and authorization that halts rather than
renders — because each one fails silently when broken.

Security reports go through [SECURITY.md](SECURITY.md), not public issues.

## Licence

[AGPL-3.0](LICENSE). Self-host it, modify it, run it for your own communities freely. The
copyleft is there so a hosted fork cannot take the work without contributing back.
