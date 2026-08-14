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
   https://<user>.github.io/<repo>/gate-test.html?video=<VIDEO_URL>&img=<IMG_URL>
   ```

5. Photograph the screen. Leave it running overnight. Photograph it again next morning.
6. Note day-1 egress in the Supabase dashboard before you start, and day-2 egress after.

The page reports V3, N1, N2, G1, G2, G4 and the V6 sleep test by itself. V1, V2, V6, V7
and G3 are checked by hand.

## Results

| ID | Gate | Blocks | Result |
|---|---|---|---|
| **V1** | TV class. `Settings → Support → About This TV` or rear sticker. `UA`/`QA`/`UN` = consumer. `LH` = commercial signage. | Whole approach | ☐ model: |
| **V2** | Browser exists and loads an external HTTPS page. | Everything | ☐ |
| **V3** | `navigator.userAgent` — read it off the gate page and photograph it. | JS/CSS baseline | ☐ UA: |
| **V6** | `Auto Power Off`, `Screen Saver`, `Brightness Optimization` can all be turned off. Uptime counter still climbing next morning. | Unattended operation | ☐ |
| **V7** | No captive portal. TVs on staff/IoT VLAN or MAC-whitelisted. Prefer wired. | Everything | ☐ |
| **N1** | TV reaches `*.supabase.co` over HTTPS. | Everything | ☐ |
| **N2** | TV holds a `wss://` connection. Judge on the 30-minute held time, not the handshake. | Realtime only | ☐ held: ___ drops: ___ |
| **G1** | Video autoplays with no remote interaction. | Video scope | ☐ |
| **G2** | Loop transition clean — no black frame, no stutter. | Video scope | ☐ |
| **G3** | Cache persistence. Day-2 egress ≈ day-1 baseline, not a repeat of the download. | Egress budget | ☐ d1: ___ MB  d2: ___ MB |
| **G4** | H.264 High decodes. Else Main, else Baseline. | Encoding spec | ☐ profile: |

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
