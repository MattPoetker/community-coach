# Security

## Reporting a vulnerability

Please report privately, through GitHub's
[Report a vulnerability](https://github.com/MattPoetker/community-coach/security/advisories/new)
form. Do not open a public issue.

Include what you did, what happened, and what you expected. A proof of concept helps, but a
clear description of the class of problem is enough to start.

This is an unfunded open-source project, so there is no bounty and no guaranteed response
time — but reports are read and taken seriously.

## What is in scope

This software is self-hosted, so the interesting boundaries are:

- **Cross-community data access.** Every tenant-owned table is scoped by `community_id`.
  Any path that returns one community's data to a member of another is the highest-severity
  bug this project can have.
- **Entitlement bypass.** Reaching paid or dripped content without the plan that includes
  it — particularly anything that yields a signed video URL.
- **Privilege escalation.** A member performing a moderator or owner action.
- **Session handling.** Session fixation, tokens surviving a password reset or a ban, or
  CSRF against the cookie-authenticated API.
- **Injection.** SQL, or stored content escaping the constrained rich-text document.

## What is not

- Findings that require an already-compromised host or database.
- Denial of service through sheer volume; rate limits are tuned per install.
- Missing hardening headers on a deployment that does not use the supplied Caddyfile.
- Anything in `preview/`, which is design reference and ships no product code.

## For people running this

- Set `SECRET_KEY_BASE` and `POSTGRES_PASSWORD` to real random values.
- Serve over HTTPS. The session cookie only gets its `__Host-` prefix and `Secure` flag
  when `FORCE_SSL=true` or `RAILS_ENV=production`.
- Do not run `db:seed` on a public host. Those accounts share a password published in the
  README, and seeding refuses in production unless you override it deliberately.
- Keep `deploy/.env` out of version control. It is gitignored.
