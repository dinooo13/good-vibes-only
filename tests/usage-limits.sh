#!/bin/bash
# Checks are single-quoted on purpose: check() evals them after the command ran.
# shellcheck disable=SC2016,SC2034
# Offline tests for the usage-limits scripts. Fake `security`, `curl` and `codexbar` binaries
# on PATH stand in for the keychain, the usage endpoint and codexbar; nothing leaves the machine.
#
# Usage: tests/usage-limits.sh
set -uo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
S=$ROOT/plugins/usage-limits/skills/usage-limits/scripts
T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT

export CLAUDE_CONFIG_DIR=$T/config   # keeps the cache and credentials away from the real ~/.claude
export PATH=$T/bin:$PATH
mkdir -p "$T/bin" "$CLAUDE_CONFIG_DIR"
TOKEN=sk-ant-oat01-TESTTOKEN_abc-123

pass=0; fail=0
ok()   { pass=$((pass + 1)); echo "ok   $1"; }
nok()  { fail=$((fail + 1)); echo "FAIL $1"; [ -n "${2:-}" ] && printf '%s\n' "$2" | sed 's/^/     /'; }
check() { if eval "$2"; then ok "$1"; else nok "$1" "${3:-}"; fi; }
iso()  { date -u -r "$1" '+%Y-%m-%dT%H:%M:%S.123456+00:00' 2>/dev/null || date -u -d "@$1" '+%Y-%m-%dT%H:%M:%S.123456+00:00'; }

# --- fakes -------------------------------------------------------------------------------
cat >"$T/bin/security" <<EOF
#!/bin/bash
[ -f "$T/no-keychain" ] && exit 44
printf '{"claudeAiOauth":{"accessToken":"%s"}}' "\$(cat "$T/token")"
EOF
cat >"$T/bin/curl" <<EOF
#!/bin/bash
echo "\$*" >>"$T/curl-argv"
cat >>"$T/curl-stdin"
echo call >>"$T/curl-calls"
cat "$T/body"; printf '\n%s' "\$(cat "$T/code")"
EOF
cat >"$T/bin/codexbar" <<EOF
#!/bin/bash
[ -f "$T/codexbar-body" ] || exit 1
cat "$T/codexbar-body"
EOF
chmod +x "$T/bin/"*

now=$(date +%s); in2h=$((now + 7200)); in3d=$((now + 259200))
body() { # five_hour_pct seven_day_pct [locked_reason]
  local lr=null; [ -n "${3:-}" ] && lr="\"$3\""
  printf '{"five_hour":{"utilization":%s,"resets_at":"%s","locked_reason":%s},"seven_day":{"utilization":%s,"resets_at":"%s"},"seven_day_opus":null,"extra_usage":null}' \
    "$1" "$(iso $in2h)" "$lr" "$2" "$(iso $in3d)" >"$T/body"
  echo 200 >"$T/code"
}
reset_fakes() { rm -f "$T"/curl-* "$T/no-keychain" "$T/codexbar-body" "$CLAUDE_CONFIG_DIR"/usage-limits/*; printf '%s' "$TOKEN" >"$T/token"; }

# --- usage.sh ----------------------------------------------------------------------------
reset_fakes; body 40 20
out=$("$S/usage.sh" --no-cache); rc=$?
check "ok verdict under the thresholds" '[ $rc = 0 ] && [ "$(jq -r .verdict <<<"$out")" = ok ]' "$out"
check "resets_epoch parsed from ISO with fraction and offset" '[ "$(jq -r .five_hour.resets_epoch <<<"$out")" = $in2h ]' "$out"
check "seconds_until_reset is relative to now" 'd=$(jq -r .five_hour.seconds_until_reset <<<"$out"); [ "$d" -le 7200 ] && [ "$d" -ge 7190 ]' "$out"
check "resume_cron is set" '[ -n "$(jq -r ".resume_cron // empty" <<<"$out")" ]' "$out"
check "token is not in curl argv" '! grep -q TESTTOKEN "$T/curl-argv"' "$(cat "$T/curl-argv")"
check "token reaches curl via stdin config" 'grep -q "^header = \"Authorization: Bearer $TOKEN\"$" "$T/curl-stdin"'
check "token is not in the output" '! grep -q TESTTOKEN <<<"$out"'
check "token is not in the cache" '! grep -rq TESTTOKEN "$CLAUDE_CONFIG_DIR/usage-limits"'
check "cache file is private" '[ "$(stat -f %Lp "$CLAUDE_CONFIG_DIR/usage-limits/usage-cache.json" 2>/dev/null || stat -c %a "$CLAUDE_CONFIG_DIR/usage-limits/usage-cache.json")" = 600 ]'

"$S/usage.sh" --brief >/dev/null
check "second call within 60s is served from the cache" '[ "$(wc -l <"$T/curl-calls" | tr -d " ")" = 1 ]'
USAGE_CACHE_SECS=0 "$S/usage.sh" --brief >/dev/null
check "USAGE_CACHE_SECS=0 bypasses the cache" '[ "$(wc -l <"$T/curl-calls" | tr -d " ")" = 2 ]'

reset_fakes; body 92 30
out=$("$S/usage.sh" --no-cache)
check "wrap_up at 92%" '[ "$(jq -r .verdict <<<"$out")" = wrap_up ] && [ "$(jq -r .resume_epoch <<<"$out")" = $in2h ]' "$out"

reset_fakes; body 50 95
out=$("$S/usage.sh" --no-cache)
check "7-day window at 95% makes it the binding reset" '[ "$(jq -r .resume_epoch <<<"$out")" = $in3d ]' "$out"

reset_fakes; body 100 30
check "blocked at 100%" '[ "$("$S/usage.sh" --no-cache | jq -r .verdict)" = blocked ]'
reset_fakes; body 10 10 rate_limited
check "blocked when a window reports locked_reason" '[ "$("$S/usage.sh" --no-cache | jq -r .verdict)" = blocked ]'

reset_fakes; body 10 10; echo 401 >"$T/code"
printf '[{"usage":{"primary":{"usedPercent":70,"resetsAt":"%s"},"secondary":{"usedPercent":5,"resetsAt":"%s"}}}]' \
  "$(date -u -r $in2h '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || date -u -d @$in2h '+%Y-%m-%dT%H:%M:%SZ')" "$(iso $in3d)" >"$T/codexbar-body"
out=$("$S/usage.sh" --no-cache)
check "falls back to codexbar when the endpoint fails" '[ "$(jq -r .source <<<"$out")" = codexbar ] && [ "$(jq -r .five_hour.used_pct <<<"$out")" = 70 ]' "$out"

reset_fakes; echo '{"error":{"type":"not_found"}}' >"$T/body"; echo 200 >"$T/code"
out=$("$S/usage.sh" --no-cache); rc=$?
check "a 200 without usage windows is not reported as ok" '[ $rc = 2 ] && jq -e .error <<<"$out" >/dev/null' "$out"

reset_fakes; body 10 10; echo 500 >"$T/code"
out=$("$S/usage.sh" --no-cache); rc=$?
check "exit 2 with an error JSON when every source fails" '[ $rc = 2 ] && jq -e .error <<<"$out" >/dev/null' "$out"

reset_fakes; body 10 10; printf 'bad"token\nheader = "X: injected' >"$T/token"
out=$("$S/usage.sh" --no-cache); rc=$?
check "a token that could break the curl config is refused" '[ $rc = 2 ] && [ ! -f "$T/curl-calls" ]' "$out"

reset_fakes; body 30 30; touch "$T/no-keychain"
printf '{"claudeAiOauth":{"accessToken":"%s"}}' "$TOKEN" >"$CLAUDE_CONFIG_DIR/.credentials.json"
out=$("$S/usage.sh" --no-cache)
check "reads ~/.claude/.credentials.json when there is no keychain entry" '[ "$(jq -r .source <<<"$out")" = oauth ]' "$out"
rm -f "$CLAUDE_CONFIG_DIR/.credentials.json"

# Rate limiting: the endpoint answers 429 and codexbar is unavailable.
reset_fakes; body 42 10
"$S/usage.sh" --no-cache >/dev/null                        # a good result lands in the cache
echo '{"error":{"type":"rate_limit_error"}}' >"$T/body"; echo 429 >"$T/code"
out=$("$S/usage.sh" --no-cache); rc=$?
check "429 falls back to the last good result, marked stale" '[ $rc = 0 ] && [ "$(jq -r .stale <<<"$out")" = true ] && [ "$(jq -r .five_hour.used_pct <<<"$out")" = 42 ]' "$out"
check "429 starts a 60s backoff" '[ "$(cut -d" " -f2 "$CLAUDE_CONFIG_DIR/usage-limits/oauth-backoff")" = 60 ]'
check "brief output says the result is stale" '"$S/usage.sh" --no-cache --brief | grep -q "^STALE (0m old"'
check "no request is sent during the backoff" '[ "$(wc -l <"$T/curl-calls" | tr -d " ")" = 2 ]'
echo "$(( $(date +%s) - 1 )) 60" >"$CLAUDE_CONFIG_DIR/usage-limits/oauth-backoff"
"$S/usage.sh" --no-cache >/dev/null
check "another failure after the backoff doubles it" '[ "$(cut -d" " -f2 "$CLAUDE_CONFIG_DIR/usage-limits/oauth-backoff")" = 120 ]'
echo "$(( $(date +%s) - 1 )) 900" >"$CLAUDE_CONFIG_DIR/usage-limits/oauth-backoff"
"$S/usage.sh" --no-cache >/dev/null
check "the backoff is capped at 15 minutes" '[ "$(cut -d" " -f2 "$CLAUDE_CONFIG_DIR/usage-limits/oauth-backoff")" = 900 ]'
out=$(USAGE_STALE_SECS=0 "$S/usage.sh" --no-cache); rc=$?
check "no stale fallback past USAGE_STALE_SECS" '[ $rc = 2 ] && jq -e .error <<<"$out" >/dev/null' "$out"
echo "$(( $(date +%s) - 1 )) 120" >"$CLAUDE_CONFIG_DIR/usage-limits/oauth-backoff"; body 43 10
out=$("$S/usage.sh" --no-cache)
check "a success clears the backoff" '[ ! -f "$CLAUDE_CONFIG_DIR/usage-limits/oauth-backoff" ] && [ "$(jq -r .stale <<<"$out")" = false ]' "$out"
reset_fakes; touch "$T/no-keychain"
"$S/usage.sh" --no-cache >/dev/null
check "a missing token does not start a backoff" '[ ! -f "$CLAUDE_CONFIG_DIR/usage-limits/oauth-backoff" ] && [ ! -f "$T/curl-calls" ]'

"$S/usage.sh" --nope 2>/dev/null; rc=$?
check "unknown argument exits 64" '[ $rc = 64 ]'
USAGE_WRAP_PCT='a[$(touch '"$T"'/pwned)]' "$S/usage.sh" 2>/dev/null; rc=$?
check "non-numeric threshold exits 64 and runs nothing" '[ $rc = 64 ] && [ ! -e "$T/pwned" ]'

# --- usage-watch.sh ----------------------------------------------------------------------
fake_usage() { # verdict pct [fail]
  cat >"$T/fake-usage" <<EOF
#!/bin/bash
[ -n "${3:-}" ] && { echo '{"error":"boom"}'; exit 2; }
[ "\${1:-}" = --brief ] && { echo "verdict=$1 brief"; exit 0; }
printf '{"verdict":"%s","five_hour":{"used_pct":%s,"seconds_until_reset":60,"resets_epoch":$((now + 1)),"resets_local":"soon local"},"resume_epoch":null,"resume_local":""}\n' "$1" "$2"
EOF
  chmod +x "$T/fake-usage"
}
export USAGE_SH=$T/fake-usage

fake_usage ok 86
out=$("$S/usage-watch.sh" 85 --interval 0); rc=$?
check "watch exits 0 once the 5h threshold is reached" '[ $rc = 0 ] && grep -q "5h at 86%" <<<"$out" && grep -q "resets soon local" <<<"$out"' "$out"
fake_usage wrap_up 20
out=$("$S/usage-watch.sh" 85 --interval 0); rc=$?
check "watch exits 0 on a wrap_up verdict below the threshold" '[ $rc = 0 ] && grep -q verdict=wrap_up <<<"$out"' "$out"
fake_usage ok 10 fail
out=$("$S/usage-watch.sh" --interval 0 --max-failures 2); rc=$?
check "watch exits 3 after repeated failures and reports the error" '[ $rc = 3 ] && grep -q boom <<<"$out"' "$out"
"$S/usage-watch.sh" --interval 2>/dev/null; rc=$?
check "watch rejects a missing option value" '[ $rc = 64 ]'
"$S/usage-watch.sh" 85abc 2>/dev/null; rc=$?
check "watch rejects a non-numeric threshold" '[ $rc = 64 ]'

# --- wait-reset.sh -----------------------------------------------------------------------
# First check says wrap_up with the reset ~1s away; later checks say ok.
cat >"$T/fake-usage" <<EOF
#!/bin/bash
[ "\${1:-}" = --brief ] && { echo "verdict=brief"; exit 0; }
n=\$(cat "$T/n" 2>/dev/null || echo 0); echo \$((n + 1)) >"$T/n"
if [ "\$n" = 0 ]; then v=wrap_up; else v=ok; fi
printf '{"verdict":"%s","five_hour":{"resets_epoch":%s},"seven_day":{"resets_epoch":null},"resume_epoch":null}\n' "\$v" "\$((\$(date +%s) + 1))"
EOF
chmod +x "$T/fake-usage"
out=$("$S/wait-reset.sh" --buffer 0 --max-sleep 5); rc=$?
check "wait-reset sleeps until the reset, re-checks, exits 0" '[ $rc = 0 ] && grep -q "5-hour reset" <<<"$out" && grep -q "verdict ok" <<<"$out" && [ "$(cat "$T/n")" = 2 ]' "$out"

fake_usage ok 10 fail
out=$(WAIT_FALLBACK_SECS=1 "$S/wait-reset.sh"); rc=$?
check "wait-reset exits 2 when usage stays unavailable" '[ $rc = 2 ] && grep -q "gave up" <<<"$out"' "$out"
"$S/wait-reset.sh" --buffer x 2>/dev/null; rc=$?
check "wait-reset rejects a non-numeric buffer" '[ $rc = 64 ]'

echo "$pass passed, $fail failed"
[ "$fail" = 0 ]
