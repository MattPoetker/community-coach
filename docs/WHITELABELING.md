# Whitelabeling

A self-hoster can put Community Coach under their own brand without touching code, without
a rebuild, and without a deploy. This document is the contract for what that covers.

## What an owner controls

All of it lives in `communities.branding` (jsonb) and is edited in **Settings → Branding**.

| Input | Effect |
|---|---|
| `accent` (OKLCH l/c/h) | Buttons, links, active nav, progress, focus rings, course covers, the whole 9-step accent ramp |
| `neutral` (hue, chroma) | All 13 surface and text steps, in both light and dark |
| `fonts.display` | Headings, figures, avatar initials, prices |
| `fonts.body` | Body copy, controls, labels |
| `fonts.mono` | Metadata and tabular figures where a theme asks for it |
| `structure.radiusScale` | Every radius, proportionally |
| `structure.density` | Every spacing and control height, proportionally |
| `structure.typeRatio` | The whole type scale's ratio |
| `preset` | Which of the four structural personalities to start from |
| `defaultMode` | `light`, `dark`, or `system` |
| `logoUrl`, `faviconUrl`, `ogImageUrl` | Identity marks, tab icon, social previews |
| Custom domain | `community.example.com` with automatic TLS |
| Email sender + template header | Transactional mail matches the brand |

Fourteen inputs, ~90 semantic tokens derived from them. Owners tune a brand, not a
stylesheet — which is the only version of this that non-designers can actually use.

## How it reaches the page

```
communities.branding (jsonb)
        │
        ▼
Branding::TokenCompiler        validates, clamps, enforces contrast
        │                      emits ONLY Layer 0 custom properties
        ▼
<style>:root{--brand-accent-h:156; …}</style>   injected in <head>, after themes.css
        │
        ▼
tokens.css derives Layer 1 ramps → Layer 2 semantics → components repaint
```

Source order matters: the injected block must come **after** `themes.css`. Both resolve at
the same specificity, so the later one wins — that is what lets an owner override their
preset without `!important` anywhere in the codebase.

The compiled block is cached against `[community_id, branding_updated_at]` and is a few
hundred bytes, so it ships inline rather than as a request.

## Why owners cannot break it

**Contrast is enforced, not trusted.** `Branding::Contrast` converts the accent to linear
sRGB, computes WCAG relative luminance, and picks whichever of white or near-black actually
wins on that colour — rather than assuming white, which is where most brandable products
produce unreadable buttons. If neither clears 4.5:1, the compiler walks the accent's
lightness until one does and returns a warning explaining what it changed. The owner keeps
their hue; their members keep a legible interface.

**Numbers are clamped, not interpolated.** `radiusScale`, `density` and `typeRatio` are
range-checked against a whitelist of known keys. A value outside the range is clamped and
warned about. A value that is not a number is dropped.

**Fonts are an allowlist.** `Branding::FontRegistry` holds the permitted families. The name
is interpolated into a Google Fonts URL and into a CSS declaration, so an open text field
would be an injection surface in two places at once. Adding a family is a one-line PR.

**Nothing else from the jsonb is emitted.** The compiler builds declarations from known
keys only; unrecognised keys in `branding` are ignored rather than passed through.

## Removing our branding entirely

Self-hosted installs have no "Powered by" anywhere in the product, and no phone-home. To
run with no third-party requests at all:

1. `FONT_SOURCE=local` — serves the registered families from your own origin instead of
   Google Fonts. `rake fonts:vendor` downloads them into `web/public/fonts`.
2. `ANALYTICS_PROVIDER=none` (the default).
3. Set `logoUrl`, `faviconUrl`, `ogImageUrl` and `APP_NAME`.

`APP_NAME` covers page titles, email subjects and the PWA manifest.

## What is not brandable, deliberately

Layout structure, component anatomy, spacing *relationships*, and the semantic status
colours (success / warning / danger / info). Status colour is meaning, not brand — a
red-on-red "past due" badge is worse for the owner than an off-brand one, and letting
owners retint those is how accessible products become inaccessible one setting at a time.

An owner who needs more than this has the source; a fork is a supported outcome, not a
failure. The point of the token layer is that the other 95% never need to.
