# Contributing

Thanks for looking. This is a self-hostable product, so the bar for a change is "would a
stranger running this on their own VPS be glad of it".

## Getting set up

```bash
# API
cd api && bundle install && bin/rails db:prepare db:seed && bin/rails server -p 3001

# Web, in a second terminal
cd web && npm install && API_INTERNAL_URL=http://localhost:3001 npm run dev
```

Seeds create a demo community. Sign in as `sara@example.com` / `correct-horse-battery`.

## Before you open a pull request

```bash
cd api && bundle exec rspec && bundle exec brakeman --quiet
cd web && npm run lint:tokens && npm run typecheck && npm run build
```

CI runs exactly these.

## Three rules that are enforced by tests, not by review

These exist because each one, when broken, fails silently rather than loudly. Please do not
work around them.

**1. Every model is tenant-scoped.** Any table owned by a community carries `community_id`
and declares `acts_as_tenant :community`. `spec/models/tenancy_spec.rb` fails the build
otherwise. A model that genuinely has no community — a `User`, say — goes on
`ApplicationRecord::GLOBAL_MODELS`; one reachable only through a scoped parent goes on
`SCOPED_VIA_PARENT`. Both need a reason in the comment.

A missed tenant scope does not raise. It serves one community's data to another.

**2. Components read tokens, never raw values.** No hex colours, no px radii, no hardcoded
font stacks, no Layer 0 or Layer 1 tokens in `components.css`. `npm run lint:tokens` fails
the build. This is the entire reason a community owner can rebrand without a deploy — see
[docs/DESIGN_SYSTEM.md](docs/DESIGN_SYSTEM.md).

The exemption list is currently empty. Every case that looked like an exception turned out
to be a missing Layer 3 token; please add the token rather than the exemption.

**3. Authorization halts, it does not render.** `render` inside a controller action sets
the response and then *carries on executing the method*. Check permissions in a
`before_action`, or raise. This codebase has shipped that bug twice — once where a
paywalled lesson still minted its signed video URL after a 403, and once where a member
got a 403 and the community record was updated anyway. Both have regression specs.

## Two ideas worth keeping straight

**Roles are not entitlement.** Pundit answers "may a moderator lock this post".
`Access::Resolver` answers "does their plan and drip schedule include this lesson". They are
separate objects with separate tests, because conflating them is how paywalls leak.

**Directions are not themes.** A theme is colour, type and spacing — data an owner edits. A
structural change to layout or information model is a different thing and ships as code.

## Commits

Conventional-ish subject line, and a body that says *why* where the why is not obvious from
the diff. If you fixed something subtle, the next person will want to know what it was.

## Security

Do not open a public issue for a vulnerability. See [SECURITY.md](SECURITY.md).
