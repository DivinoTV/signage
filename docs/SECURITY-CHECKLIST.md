# Security checklist (brief v2.1 §4.3) — release blocker

The front-end is static, so the Supabase URL and anon key are visible to anyone who
views source. That is normal Supabase design, and it means:

> **RLS plus closed signup is the only thing protecting this system.**

## Run it

```bash
./verify-security.sh https://xxxx.supabase.co <anon-key>
```

Public key only — the script refuses an obvious service-role or secret key, but it cannot
catch every form, so check what you paste. Every check must PASS. **Any single failure is
a release blocker, and a SKIP is untested rather than safe.**

| Check | Required result | Method |
|---|---|---|
| `INSERT` into `assets` | refused | status code |
| `SELECT` on `assets` where `is_active = false` | returns nothing | body |
| `UPDATE` on `assets` | zero rows affected | needs a readable row |
| `DELETE` from `assets` | zero rows affected | needs a readable row + `--include-destructive` |
| `SELECT` on `zones` | returns nothing (admin-only, §2.10 FP3) | body |
| `INSERT` into `zones` | refused | status code |
| Upload to the `signage` bucket | refused | status code |
| Delete from the `signage` bucket | refused | status code |
| Public signup | refused | status code |

### Why UPDATE and DELETE are not status-code checks

PostgREST answers **2xx when zero rows match a filter**, and RLS blocks `UPDATE`/`DELETE`
by filtering rows down to zero rather than raising an error. For those two verbs a status
code therefore cannot tell "blocked by policy" apart from "nothing matched" — an earlier
version of this script checked the code and reported false failures against an empty
table. The sound method, and what the script now does:

- operate on a row the public key can genuinely **read**, and
- ask for the affected rows back with `Prefer: return=representation` — `[]` proves
  nothing was touched.

Consequences worth knowing:

- **With no published slides, both probes SKIP.** There is nothing to attack, so they are
  genuinely unverified. Publish one slide, then run again. Exit code 3 means "no failures
  but not a clean sheet".
- **The UPDATE probe is safe to re-run.** It writes `sort_order` back to the value the row
  already holds, so an open policy shows up in the response without changing any data.
- **The DELETE probe really deletes** if the policy is open, which is why it needs
  `--include-destructive`. Publish a throwaway slide, run it with the flag, then remove
  the flag for routine quarterly runs.

A `SKIP` mentioning the server could not be reached is neither a pass nor a breach — fix
the URL or the connection and run again.

If an `INSERT` ever succeeds, delete the `__rls_probe__` rows it left behind, re-apply
`db/policies.sql`, and re-run.

## Not covered by the script

- **Public signup must be off in the dashboard.** The script probes the signup endpoint,
  which is the real test, but confirm the setting visually too — it is the single
  highest-consequence switch in the project (§5.1 step 5).
- **`service_role` key must not appear anywhere in this repo.** Quick check:

  ```bash
  git grep -nE "service_role|eyJ[A-Za-z0-9_-]{80,}" -- . ':!*.md'
  ```

  The anon key will match the second pattern once it is filled in — that is expected and
  fine. Anything labelled `service_role` is not.

## Known authorisation gap

The `authenticated` policy grants full access to **all six properties**. Any account can
edit any property's content. Acceptable while Samuel is the only operator. Before issuing
accounts to property staff, this needs per-property scoping and a restricted delete right
(§2.7, open question 3).

## Log

Re-run quarterly — policies drift as features are added (§5.5).

| Date | Run by | Result |
|---|---|---|
| 2026-08-13 | Samuel | 7 pass, 0 fail, 2 SKIP (no slides published yet). Public signup confirmed off (422). Re-run after the first slide. |
| 2026-08-13 | Samuel | **ALL 9 PASS** with `--include-destructive`, against 3 published slides. UPDATE and DELETE both zero rows affected — the write probes finally had a real row to attack and were refused. Clean sheet. Next due 2026-11-13. |
