#!/bin/bash
# Security verification (brief v2.1 §4.3). RELEASE BLOCKER.
#
#   ./verify-security.sh <supabase-url> <anon-or-publishable-key> [--include-destructive]
#
# Re-run quarterly (§5.5) — policies drift as features are added.
# Uses only the public key, which is what an attacker has.
#
# WHY THIS IS NOT JUST "CHECK THE STATUS CODE"
# PostgREST answers 2xx when zero rows match a filter, and RLS blocks UPDATE/DELETE by
# filtering rows down to zero rather than raising an error. So for those two verbs a
# status code cannot tell "blocked by policy" apart from "nothing matched". Two things
# fix it: operate on a row the public key can genuinely read, and ask for the affected
# rows back with `Prefer: return=representation` — `[]` means nothing was touched.
# INSERT, storage and signup DO raise real errors, so a status code is sound for those.

set -u
URL="${1:-}"
KEY="${2:-}"
DESTRUCTIVE=0
for a in "$@"; do [ "$a" = "--include-destructive" ] && DESTRUCTIVE=1; done

if [ -z "$URL" ] || [ -z "$KEY" ]; then
  echo "usage: $0 <supabase-url> <anon-or-publishable-key> [--include-destructive]"
  exit 2
fi
case "$KEY" in
  *service_role*|*"service-role"*|sb_secret_*)
    echo "STOP: that looks like a service-role / secret key. Use the public key only."; exit 2;;
esac
URL="${URL%/}"; URL="${URL%/rest/v1}"        # tolerate a pasted REST path
command -v node >/dev/null || { echo "STOP: node is required to read JSON responses."; exit 2; }

PASS=0; FAIL=0; SKIP=0
H_KEY="apikey: $KEY"
H_AUTH="Authorization: Bearer $KEY"
H_JSON="Content-Type: application/json"
H_REP="Prefer: return=representation"

pass(){ echo "  PASS  $1"; PASS=$((PASS+1)); }
bad(){  echo "  FAIL  $1"; echo "        $2"; FAIL=$((FAIL+1)); }
skip(){ echo "  SKIP  $1"; echo "        $2"; SKIP=$((SKIP+1)); }

# first element's field, empty on any problem
field(){ node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{try{const a=JSON.parse(s);
  process.stdout.write(a&&a[0]&&a[0][process.argv[1]]!==undefined?String(a[0][process.argv[1]]):"")}
  catch(e){process.stdout.write("")}})' "$1"; }

# status-code check, for verbs that genuinely raise errors
check_refused(){
  local label="$1"; shift
  local out code
  out=$(curl -s -w $'\n%{http_code}' "$@" 2>/dev/null)
  code=$(printf '%s' "$out" | tail -1)
  out=$(printf '%s' "$out" | sed '$d')
  if [ -z "$code" ] || [ "$code" = "000" ]; then
    skip "$label" "could not reach the server. Check the URL and your internet."
  elif [ "$code" -ge 400 ] 2>/dev/null; then
    pass "$label — refused ($code)"
  else
    bad "$label — ACCEPTED ($code). RELEASE BLOCKER." "response: $(printf '%s' "$out" | head -c 200)"
  fi
}

check_empty(){
  local label="$1"; shift
  local body; body=$(curl -s "$@" 2>/dev/null)
  if [ "$body" = "[]" ]; then pass "$label — returned nothing"
  elif [ -z "$body" ]; then skip "$label" "no response. Check the URL and your internet."
  else bad "$label — LEAKED DATA." "$(printf '%s' "$body" | head -c 200)"; fi
}

echo
echo "Verifying $URL with the public key only"
[ "$DESTRUCTIVE" = 1 ] && echo "--include-destructive is ON: the DELETE probe will really delete if RLS is open."
echo

echo "assets table"
check_refused "INSERT into assets" \
  -X POST "$URL/rest/v1/assets" -H "$H_KEY" -H "$H_AUTH" -H "$H_JSON" \
  -d '{"property":"__rls_probe__","media_url":"probe","media_type":"image"}'

check_empty "SELECT hidden (is_active=false) rows" \
  "$URL/rest/v1/assets?select=id&is_active=eq.false" -H "$H_KEY" -H "$H_AUTH"

# A row the public key can actually read — without one, the write probes prove nothing.
ROW=$(curl -s "$URL/rest/v1/assets?select=id,sort_order&is_active=eq.true&limit=1" -H "$H_KEY" -H "$H_AUTH")
ROW_ID=$(printf '%s' "$ROW" | field id)
ROW_ORDER=$(printf '%s' "$ROW" | field sort_order)
[ -n "$ROW_ORDER" ] || ROW_ORDER=0

if [ -z "$ROW_ID" ]; then
  skip "UPDATE on assets" "no readable row to attack — UNVERIFIED, not safe. Publish one slide and run again."
  skip "DELETE from assets" "no readable row to attack — UNVERIFIED, not safe. Publish one slide and run again."
else
  # No-op write: set sort_order to the value it already holds. If the policy is open the
  # row comes back (breach) but the data is unchanged, so this probe is safe to re-run.
  RESP=$(curl -s -X PATCH "$URL/rest/v1/assets?id=eq.$ROW_ID" \
    -H "$H_KEY" -H "$H_AUTH" -H "$H_JSON" -H "$H_REP" -d "{\"sort_order\":$ROW_ORDER}")
  if [ "$RESP" = "[]" ]; then
    pass "UPDATE on assets — zero rows affected"
  else
    bad "UPDATE on assets — WROTE TO A LIVE ROW. RELEASE BLOCKER." "$(printf '%s' "$RESP" | head -c 200)"
  fi

  if [ "$DESTRUCTIVE" = 1 ]; then
    RESP=$(curl -s -X DELETE "$URL/rest/v1/assets?id=eq.$ROW_ID" \
      -H "$H_KEY" -H "$H_AUTH" -H "$H_REP")
    if [ "$RESP" = "[]" ]; then
      pass "DELETE from assets — zero rows affected"
    else
      bad "DELETE from assets — REALLY DELETED A SLIDE. RELEASE BLOCKER." \
          "Restore it from your latest JSON export. Deleted: $(printf '%s' "$RESP" | head -c 160)"
    fi
  else
    skip "DELETE from assets" "not attempted — it destroys a real slide if the policy is open. Re-run with --include-destructive once you have a throwaway slide published."
  fi
fi

echo
echo "zones table (admin-only — the TV never reads it)"
check_empty "SELECT on zones" "$URL/rest/v1/zones?select=slug" -H "$H_KEY" -H "$H_AUTH"
check_refused "INSERT into zones" \
  -X POST "$URL/rest/v1/zones" -H "$H_KEY" -H "$H_AUTH" -H "$H_JSON" \
  -d '{"property":"__rls_probe__","slug":"probe","label":"probe"}'

echo
echo "signage bucket"
check_refused "UPLOAD to signage" \
  -X POST "$URL/storage/v1/object/signage/__rls_probe__.txt" -H "$H_KEY" -H "$H_AUTH" \
  -H "Content-Type: text/plain" --data-binary "probe"
check_refused "DELETE from signage" \
  -X DELETE "$URL/storage/v1/object/signage/__rls_probe__.txt" -H "$H_KEY" -H "$H_AUTH"

echo
echo "auth"
check_refused "Public signup" \
  -X POST "$URL/auth/v1/signup" -H "$H_KEY" -H "$H_JSON" \
  -d '{"email":"rls-probe@example.com","password":"Pr0be-'"$$"'-xyz"}'

echo
echo "----------------------------------------"
if [ "$FAIL" -gt 0 ]; then
  echo "$FAIL FAILED, $PASS passed, $SKIP skipped."
  echo "DO NOT RELEASE. Re-apply db/policies.sql, confirm public signup is off, run again."
  echo "If an INSERT succeeded, delete the __rls_probe__ rows it left behind."
  exit 1
elif [ "$SKIP" -gt 0 ]; then
  echo "$PASS passed, 0 failed, $SKIP UNVERIFIED (see SKIP above)."
  echo "Not a clean sheet yet — a skipped check is untested, not safe."
  exit 3
else
  echo "ALL $PASS CHECKS PASSED — safe to release."
  echo "Record the date in docs/SECURITY-CHECKLIST.md and commit."
fi
