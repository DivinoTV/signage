# Validation gates — record results here and commit

Brief v2.1 §1.5. **Blocking.** Nothing in Phase 3 beyond what is already committed
should be built until this file is filled in. Two of these can stop the project.

Run on a real guest-room TV, on the real property network. Not a desktop browser,
not an emulator.

## How to run

1. Publish this repo to GitHub Pages (§5.1 step 7).
2. Fill in `SUPABASE_URL` / `SUPABASE_ANON` at the top of `gate-test.html`.
3. Encode one test video (below), upload it plus one still to the `signage` bucket,
   copy the public URLs.
4. On the TV: Home → Internet → open

   ```
   https://divinotv.github.io/signage/gate-test.html?video=<VIDEO_URL>&img=<IMG_URL>
   ```

5. Photograph the screen. Leave it running overnight. Photograph it again next morning.
6. Note day-1 egress in the Supabase dashboard before you start, and day-2 egress after.

The page reports V3, N1, N2, G1, G2, G4 and the V6 sleep test by itself. V1, V2, V6, V7
and G3 are checked by hand.

## Results

**Run 1 — 2026-08-13, Divino Gili Air, one guest room.** Photographed.

| ID | Gate | Blocks | Result |
|---|---|---|---|
| **V1** | TV class. `UA`/`QA`/`UN` = consumer. `LH` = commercial signage. | Whole approach | ◐ **consumer** — UA reports `SMART-TV … Tizen 10.0 … SamsungBrowser/9.0`, and a commercial `LH` panel has no such browser. Model number off the sticker still to be recorded. |
| **V2** | Browser exists and loads an external HTTPS page. | Everything | ☑ **PASS** — loaded `divinotv.github.io` over HTTPS |
| **V3** | `navigator.userAgent` — sets the JS/CSS baseline. | Language features | ☑ **RECORDED — and it changes an assumption, see below** |
| **V6** | `Auto Power Off`, `Screen Saver`, `Brightness Optimization` all off. | Unattended operation | ☐ **NOT TESTED** — uptime only reached 0:00:43. Needs an overnight run. |
| **V7** | No captive portal. | Everything | ◐ **likely clear** — an external HTTPS page loaded without a login interstitial. Not conclusive until a power-cycle and reconnect are tested. |
| **N1** | TV reaches `*.supabase.co` over HTTPS. | Everything | ☑ **PASS** — `REACHABLE (200)`, 3 rows returned |
| **N2** | TV holds a `wss://` connection. Judge on 30-minute held time. | Realtime only | ◐ **PROMISING, not passed** — `OPEN`, held 0:00:42, **0 drops**. The gate requires 30 minutes idle; 42 seconds does not test hotel-network idle timeouts. |
| **G1** | Video autoplays with no remote interaction. | Video scope | ☐ **INCONCLUSIVE** — reported `AUTOPLAY BLOCKED`, but that label was wrong (see below). Retest. |
| **G2** | Loop transition clean. | Video scope | ☐ **NOT TESTED** — 0 loops, no video actually played |
| **G3** | Cache persistence. Day-2 egress ≈ day-1 baseline. | Egress budget | ☐ **NOT TESTED** — needs the overnight run |
| **G4** | H.264 High decodes. Else Main, else Baseline. | Encoding spec | ☑ **PASS at High** — `canPlayType` returns `probably` for High, Main **and** Baseline |

### V3 — the baseline is far newer than the brief assumed

```
Mozilla/5.0 (SMART-TV; Linux; Tizen 10.0) AppleWebKit/537.36 (KHTML, like Gecko)
SamsungBrowser/9.0 Chrome/130.0.6723.116 TV Safari/537.36
```

**Chromium 130.** The brief's §2.5 baseline — "ES5 + Promise + XHR until V3 says otherwise,
no `?.`, no `async`/`await`, no CSS Grid `gap`" — was the right assumption to start from and
is now measured to be unnecessary. `fetch`, `async`/`await`, optional chaining, `object-fit`
and Grid `gap` are all available.

Nothing is being rewritten over this: the shipped ES5 runs fine on Chromium 130, and churn
on a working unattended app buys nothing. It is recorded so future changes are not hobbled
by a constraint that no longer exists — and so that the constraint is reinstated if a
different, older panel ever appears at another property. **Re-run V3 on the first TV at
each new property.**

### G1 — the failure was in the test, not the TV

Reported `AUTOPLAY BLOCKED` and `image loads FAILED`. Both were false:

- All three published images return **HTTP 200** and load correctly off Supabase Storage.
- **G4 says the H.264 decoder is present at every profile.**
- The `?video=` and `?img=` URLs were hand-typed on a TV remote — ~120 characters each.
- The page reported any rejected `play()` as `AUTOPLAY BLOCKED`, which hid the difference
  between `NotAllowedError` (the TV really refused) and `NotSupportedError` (bad file).

Both fixed: the gate page now **reads the published playlist and tests the first image and
video itself** — nothing to type — and a rejected `play()` reports `err.name`.

**G1 and G2 remain genuinely unknown.** No video has been published yet, so there is still
nothing to autoplay.

---

## Run 2 — 2026-08-14, overnight, same room

| ID | Gate | Result |
|---|---|---|
| **V6** | Sleep settings | ☑ **PASS** — uptime **13:52:50**. The TV never slept, never blanked. |
| **N2** | WebSocket held | ☑ **PASS** — held **7:11:48**, **2 drops** across ~14 hours. The bar was 30 minutes idle. **Realtime is viable — M6 is unblocked.** |
| **N1** | Supabase reachable | ☑ **PASS** — `REACHABLE (200)`, 4 rows |
| **G4** | Codec | ☑ **PASS** — High, Main, Baseline all `probably` |
| image | Loads from Storage | ☑ **OK 1920x1080** — confirms run 1's `FAILED` was the hand-typed URL, not the TV |
| **G3** | Cache persistence | ✗ **FAIL for video, PASS for images** — see below |
| **G1** | Video autoplay | ✗ **FAIL** — `SOURCE FAILED (media error 2)` = `MEDIA_ERR_NETWORK`, the download died partway and restarted, 734 times |
| **G2** | Loop transition | ✗ not reached — no clean playback to judge |

### G3 — measured, and it cost 45 GB of overage

**49.96 GB of cached egress in one night, against a 5 GB monthly allowance.** One TV.

The stored metadata was correct on every file — `cacheControl = max-age=31536000`, exactly
what the admin panel sets. Supabase overrides it on the response:

```
cache-control: no-cache        cf-cache-status: REVALIDATED
```

`no-cache` means "revalidate before use", not "do not store". Measured against the real
objects:

| Request | Result |
|---|---|
| Image, `If-None-Match` | **304, 0 bytes** |
| Video, `If-None-Match` | **304, 0 bytes** |
| Video, `Range:` **with** etag | **304, 0 bytes** |
| Video, `Range:` **without** etag | **206, full transfer** |

So revalidation is cheap and the server supports it. **This TV's media element does not
send the etag on its range requests** — every loop re-fetched the whole 32.5 MB file.
49.96 GB ÷ 32.5 MB = **1,572 full downloads in 14 hours**, one roughly every 32 seconds.

Two compounding causes, both fixable:

1. **The file was 32.5 MB** — over the 12–25 MB target and far above the 6 Mbps starting
   bitrate in §2.9. On island internet the download could not finish before the element
   gave up, so it restarted, forever.
2. **No browser-side media caching on this panel.** This is not specific to `loop`: the TV
   app rotates a 4-slide playlist every 40 seconds, so a video would be re-fetched about
   2,160 times a day per TV regardless.

**Conclusion: video cannot be served from Supabase Storage on this plan.** Not a bitrate
problem alone — even a 5 MB clip re-fetched 2,160×/day/TV is 10.8 GB/day. This is exactly
the situation §2.9 escalation path 2 exists for: move video to GitHub Releases, where
`media_url` stays absolute (FP4) and the TV cannot tell the difference.

**Images are fine.** They revalidate at 304/0 bytes and are unaffected.

### What was fixed as a result

- **`gate-test.html` now has a circuit breaker** — stops after 20 clean loops, 3 media
  errors, or 5 minutes, whichever comes first. A tool designed to be left running
  unattended must not be able to spend a month's egress in a night.
- **`index.html` memoises a successful probe for one poll cycle.** Re-probing on every
  slide change was 17,280 conditional requests per TV per day; at 22 TVs the 304 response
  headers alone were 3.2 GB/month against a 5 GB cap. Now 0.2 GB/month.

## Still open after run 1

| What | How |
|---|---|
| **V6 + G3** | Leave `gate-test.html` running overnight. Check the uptime counter next morning, and compare day-1 vs day-2 egress in the Supabase dashboard. |
| **N2 proper** | Same overnight run — read `N2 held / drops` in the morning. 30 minutes is the bar; a night is better. |
| **G1 + G2** | Publish one H.264 video, then reopen the gate page. It will pick the video up automatically. |
| **V1 model number** | Off the rear sticker or `Settings → Support → About This TV`. |
| **V7 conclusive** | Power-cycle the TV, let it rejoin the network, confirm no login page appears. |

Also record: does the browser keep its session across a power cycle, and does the page
reopen by itself or need the 3-press routine?

- Session across power cycle: ☐
- Reopens automatically: ☐

## Decision gates (§1.6)

```
V1 = commercial (LH…)    →  STOP. Use the TV's built-in URL Launcher.
                             §2.6–2.9 still apply; Phase 5 changes substantially.

V7 = captive portal      →  STOP. Resolve with property IT. No software fix exists.

N1 = blocked             →  STOP. Escalate to property IT for an allowlist.

N2 = blocked/unstable    →  Realtime unavailable. Reconciliation polling only, 5 min.
                             A degradation, not a failure. Do NOT change stack.

G1 or G2 = fail          →  Change playback, not the stack. Ken Burns on stills (§2.4.4).

G3 = fail                →  Reduce payload per zone, re-test. Still failing → §2.9 path 2.

G4 = fail at all profiles →  Video out of scope for in-room TVs. Stills only.
```

## Test video encode (§ appendix, 6 Mbps starting point)

```bash
ffmpeg -i input.mov -c:v libx264 -profile:v high -pix_fmt yuv420p \
  -vf "scale=1920:1080,fps=30" -b:v 6M -maxrate 8M -bufsize 12M \
  -an -movflags +faststart output.mp4
```

For the G4 fallback ladder, swap `-profile:v high` for `main`, then `baseline`.
The gate page also reports `canPlayType` for all three profiles immediately, before
you upload anything — if High reports `no` there, encode Main instead and save a trip.
