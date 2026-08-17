# Multi-Property TV Signage

Guest-room TV signage for Divino Gili Air, Divino Caldera, Kanzen Gili Air and Oniro.
Only Divino Gili Air is operating so far. Spec: `PROJECT_BRIEF_v2.1.md` (kept out of this
repo — see `.gitignore`), with the corrections recorded below.

Static files on GitHub Pages. No server. Supabase holds the data, the media and the auth.

## What is here

| Path | What |
|---|---|
| `index.html` | TV app. Self-contained, ES5 + XHR, no library, no build step. |
| `gate-test.html` | M0 + every §1.5 gate on one page. Run this before anything else. |
| `version.json` | Version string. The TV polls it and reloads when it changes. |
| `db/schema.sql` | Tables, index, FK. Run first. |
| `db/policies.sql` | RLS. The only security layer. Run second. |
| `db/seed-zones.sql` | Zone seed. Run third. |
| `db/realtime.sql` | Realtime publication + the `revision` change signal. Run fourth — **Realtime is silent without it, and hiding a slide is silent without the revision part.** |
| `test-realtime.js` | `node test-realtime.js` — the Realtime state machine, no network needed. |
| `admin/index.html` | Admin app. Single static file, no build step. |
| `verify-security.sh` | Runs every §4.3 check. Release blocker, re-run quarterly. |
| `docs/SETUP.md` | Step-by-step setup, written for a non-technical operator. |
| `docs/GATES.md` | Blocking gate results. **Fill in and commit.** |
| `docs/SECURITY-CHECKLIST.md` | What the script covers, and what it does not. |
| `docs/CONTENT-SOP.md` | Artwork specs and the publish routine, for the operator. |
| `docs/TV-SETUP.md` | Per-TV provisioning sheet. One per screen. |
| `docs/FRONT-DESK-CARD.md` | Printable morning routine for hotel staff. |
| `test-playlist.js` | `node test-playlist.js` — checks the filter that prevents blank screens. |
| `fallback/` | Offline slides, served. See below. |
| `assets-src/` | Full-resolution artwork sources. Not served. |

Start at [docs/SETUP.md](docs/SETUP.md).

The admin app's JSON exports are the only backup that exists (§2.7). Committing them to
this repo is a reasonable place to keep them — free, off-machine, and versioned. They are
deliberately **not** in `.gitignore`, so an export saved into this folder does get pushed
rather than silently skipped.

Not built yet, and why: see the bottom of this file.

## Setup

1. Create the Supabase project. Note the URL and anon key.
2. Run `db/schema.sql`, `db/policies.sql`, `db/seed-zones.sql`, `db/realtime.sql` in the SQL editor.
3. Create the `signage` bucket, **public read**.
4. Create the admin user by hand in the dashboard, then **disable public signup**.
5. Paste the URL and anon key into the `CFG` block at the top of `index.html`
   *and* the two constants at the top of `gate-test.html`. Two places, edited once —
   the TV app stays a single self-contained file with nothing extra on its critical path.
6. Push to a **public** GitHub repo (Pages free tier requires public). Nothing sensitive
   goes in here: the anon key is fine, the service-role key must never appear.
7. `Settings → Pages → Deploy from a branch → main → / (root)`.
8. Run the gates. Record them in `docs/GATES.md`.

## TV URL

```
https://divinotv.github.io/signage/?property=divino-gili-air&type=deluxe
```

Property slugs are `divino-caldera`, `divino-gili-air`, `kanzen-gili-air`, `oniro`.

**The brief's §2.6 property list is wrong** — it names six properties including
`divino-suites` and `kanzen-santorini`, which do not exist. The owner corrected it to the
four above on 2026-08-12. Only **`divino-gili-air`** is operating so far; the other three
are commented out in `db/seed-zones.sql` and go live by uncommenting their block.

The slug is baked into every TV's bookmarked URL, so it must not be renamed once TVs are
provisioned (§2.10). The admin panel's property dropdown is built from the `zones` table,
so a property with no zone rows does not appear in the admin at all.

Both values are shape-validated against `^[a-z0-9-]{1,32}$`. A typo falls back to
shared (`zone = NULL`) content rather than an error. A missing `property` shows the
offline slide. Add `&debug=1` for the diagnostics overlay — that is the only field
debugging tool the TV has.

## Offline fallback

Three tiers, all in the repo. They cannot live in Supabase — they are exactly what
shows when Supabase is unreachable.

1. `fallback/offline-<property>.jpg` — that property's own artwork.
2. `fallback/offline.jpg` — shared, optional.
3. Dark screen with the property name, hardcoded.

A property with no artwork yet falls straight through to the next tier, so files can be
added one at a time with no code change. Changing them is a commit, not an admin upload —
so keep them timeless: no dates, no promos.

Sources live in `assets-src/` and are not served. Export to
`fallback/offline-<property>.jpg` at 1920×1080, JPEG, 300–500 KB (§2.9).

## Not built yet

| Piece | Blocked on |
|---|---|
| Video playback (M8) | External hosting. G4 passed, but G1/G3 failed: this panel re-fetches the whole file every loop — 49.96 GB in one night. Video rows are skipped and logged. See GATES.md. |
| Motion polish (M7) | Needs 10 minutes observed on a real TV, not a desktop. |
| Samsung menu paths in `TV-SETUP.md` | Vary by model year — fill in from the first TV. |

## Decisions taken on the brief's open questions

**Open question 4 — scheduled content: IN for v1.** `starts_at` / `ends_at` are
filtered on the TV ([index.html:145](index.html:145)), re-evaluated on every 5-minute
poll. The cost was two lines; the alternative is trusting six properties' worth of
promos to be switched off by hand on the right day. `is_active` stays the instant kill
switch, this is the set-and-forget scheduler. They are different tools.

**UI language: English throughout.** Owner's decision, and it **overrides §2.10 FP5**.
The brief specifies the admin dropdown label as "Kategori / Area" and an option reading
"Semua kategori"; these become **"Category / Area"** and **"All categories"**. The
reasoning behind FP5 still stands — the operator-facing label is a different concern
from the column name `zone` — only the language changes.

## Deviations from the brief

Raised rather than substituted silently, per standing rule 5.

**§2.5 — `fetch` feature detection.** The brief says to feature-detect `fetch` and fall
back to XHR, and in the same section says to implement the playlist read with XHR. This
ships XHR only: one code path, works on the oldest engine, and `fetch` buys nothing on a
request this small.

**§0.2 / §3.1 — no framework or build step in the admin app.** A framework is "permitted
and encouraged" and `admin-src/` was to hold source separate from built output. The admin
app is one screen with a list and a form; React would earn nothing and would add a build
step before every deploy. It ships as a single static `admin/index.html`, so there is no
`admin-src/` and no build. `supabase-js` loads from a CDN here — forbidden on the TV,
fine on the admin, because a CDN failure means the operator retries rather than a guest
room going blank (§0.2 failure cost).

**§2.5 — Realtime uses a raw WebSocket, not a vendored `supabase-js` bundle.** The brief
asks for the UMD bundle committed to the repo and warns it must never come from a CDN. The
reasoning behind that warning is sound and is why it is not on a CDN here either — but the
bundle itself turned out to be unnecessary. Gate run 2 held exactly this kind of raw socket
for 7h11m with 2 drops across 14 hours on the actual TV, and the client needs about 70
lines against a 120 KB dependency. It also removes the brief's own stated worry — "if the
bundle fails to parse on the TV's engine" — because there is no bundle.

What makes the tradeoff safe is that the payload is never read. Any change to `assets`
simply means "refetch", and `fetchPlaylist` already validates before adopting (§3.2.2). So
there is no protocol surface to get subtly wrong, and every failure path lands on polling,
which already works. `test-realtime.js` pins the one property that matters: polling may
only relax to 15 minutes when the subscription is genuinely confirmed.

**§3.3 — reorder buttons instead of drag-and-drop.** HTML5 drag-and-drop does not work in
mobile browsers, and G6 requires the full update cycle to be completable on a phone. Each
row has ↑/↓ buttons: works on phone and desktop, no library. A move rewrites `sort_order`
across the whole list, so it also repairs duplicate values.

**§3.3 — delete removes the row and the media file.** Shipped row-only at first, on the
reasoning that §5.6's recovery path is a JSON re-import and that can only restore media if
the file still exists. Changed on the owner's decision 2026-08-14: orphaned files were
silently eating the 1 GB storage cap, and that cost lands on him. The confirm prompt states
plainly that the file cannot be recovered. Two guards: a file shared by another row is
kept, and a `media_url` hosted outside the bucket is left alone — which is the case video
will be in once it moves to external hosting (§2.9 path 2, FP4). "Hide from TVs" remains
the prominent, reversible action.
