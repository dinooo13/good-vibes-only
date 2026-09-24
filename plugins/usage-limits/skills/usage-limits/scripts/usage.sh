#!/bin/bash
# Print Claude Code subscription usage (5-hour + 7-day windows) as normalized JSON.
# Source order: Anthropic OAuth usage endpoint (token from Claude Code's credential store:
# the macOS keychain, else $CLAUDE_CONFIG_DIR/.credentials.json), then
# `codexbar usage --provider claude --format json` as fallback.
#
# Usage: usage.sh [--brief] [--no-cache]
# Env:   USAGE_WRAP_PCT   (default 90)  -> verdict "wrap_up" at/above this
#        USAGE_BLOCK_PCT  (default 100) -> verdict "blocked" at/above this
#        USAGE_CACHE_SECS (default 60)
#        CLAUDE_CONFIG_DIR (default ~/.claude) holds the cache and, off macOS, the credentials
# Exit:  0 usage printed
#        2 usage unavailable; prints {"error": ...}
#        64 bad argument or setting
set -euo pipefail
umask 077

bad() { echo "usage.sh: $*" >&2; exit 64; }
is_num() { case "$1" in ''|*[!0-9]*) return 1;; esac; }

WRAP=${USAGE_WRAP_PCT:-90}
BLOCK=${USAGE_BLOCK_PCT:-100}
CACHE_SECS=${USAGE_CACHE_SECS:-60}
is_num "$WRAP" || bad "USAGE_WRAP_PCT must be a whole number"
is_num "$BLOCK" || bad "USAGE_BLOCK_PCT must be a whole number"
is_num "$CACHE_SECS" || bad "USAGE_CACHE_SECS must be a whole number"

BRIEF=0; NOCACHE=0
for a in "$@"; do
  case "$a" in
    --brief) BRIEF=1;;
    --no-cache) NOCACHE=1;;
    *) bad "unknown argument: $a";;
  esac
done

CONFIG_DIR=${CLAUDE_CONFIG_DIR:-$HOME/.claude}
CACHE_DIR=$CONFIG_DIR/usage-limits
CACHE=$CACHE_DIR/usage-cache.json   # not cache.json: older copies of this skill use that layout
mkdir -p "$CACHE_DIR"
chmod 700 "$CACHE_DIR" 2>/dev/null || true   # the cache includes billing data (extra_usage)

now=$(date +%s)

# Epoch -> local time string. BSD date takes -r <epoch>, GNU date takes -d @<epoch>.
fmt_epoch() { date -r "$1" "$2" 2>/dev/null || date -d "@$1" "$2"; }

# Timestamp parsing shared by both sources: ISO 8601 with optional fraction and any UTC offset.
# Unparseable values become null instead of aborting the whole document.
# shellcheck disable=SC2016  # jq code, not shell expansions
JQ_DEFS='
  def tzsecs: if . == null or . == "Z" then 0
    else gsub(":"; "") as $t
      | (if $t[0:1] == "-" then -1 else 1 end) * (($t[1:3] | tonumber) * 3600 + ($t[3:5] | tonumber) * 60) end;
  def ep: if . == null then null
    else (capture("^(?<dt>[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2})(\\.[0-9]+)?(?<tz>Z|[+-][0-9]{2}:?[0-9]{2})?$")
          | (.dt + "Z" | fromdateiso8601) - (.tz | tzsecs)) // null end;'

# Print the OAuth access token. Secrets only travel through pipes (never argv, where `ps`
# shows them, and never here-strings, which bash writes to a temp file).
read_token() {
  local creds="" tok
  if command -v security >/dev/null 2>&1; then
    creds=$(security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null) || creds=""
  fi
  if [ -z "$creds" ] && [ -r "$CONFIG_DIR/.credentials.json" ]; then
    creds=$(cat "$CONFIG_DIR/.credentials.json")
  fi
  [ -n "$creds" ] || return 1
  tok=$(printf '%s' "$creds" | jq -r '.claudeAiOauth.accessToken // empty' 2>/dev/null) || return 1
  # The token goes into a curl config line below; refuse anything that could break out of the quotes.
  case "$tok" in ''|*[!A-Za-z0-9._~+/=-]*) return 1;; esac
  printf '%s' "$tok"
}

fetch_oauth() {
  local tok resp code
  tok=$(read_token) || return 1
  # curl reads the Authorization header from a config on stdin (-K -), so the token never
  # appears in its argv. No -L: the header must not follow a redirect to another host.
  resp=$(printf 'header = "Authorization: Bearer %s"\n' "$tok" \
    | curl -sS -m 15 --proto =https -K - -w '\n%{http_code}' \
        -H "anthropic-beta: oauth-2025-04-20" \
        "https://api.anthropic.com/api/oauth/usage" 2>/dev/null) || return 1
  code=${resp##*$'\n'}
  [ "$code" = "200" ] || return 1
  printf '%s' "${resp%$'\n'*}" | jq -ce --argjson now "$now" "$JQ_DEFS"'
    def win: if . == null then null else {
      used_pct: (.utilization // 0),
      resets_at: .resets_at,
      resets_epoch: (.resets_at | ep),
      locked_reason: .locked_reason } end;
    if type != "object" or (has("five_hour") | not) then error("unexpected response") else . end
    | { source: "oauth", fetched_at: $now,
        five_hour: (.five_hour | win),
        seven_day: (.seven_day | win),
        seven_day_opus: (.seven_day_opus | win),
        seven_day_sonnet: (.seven_day_sonnet | win),
        extra_usage: (.extra_usage // null) }' 2>/dev/null
}

fetch_codexbar() {
  command -v codexbar >/dev/null 2>&1 || return 1
  codexbar usage --provider claude --format json 2>/dev/null \
    | jq -ce --argjson now "$now" "$JQ_DEFS"'
    def win: if . == null then null else {
      used_pct: (.usedPercent // 0),
      resets_at: .resetsAt,
      resets_epoch: (.resetsAt | ep),
      locked_reason: null } end;
    .[0].usage
    | if type != "object" or (has("primary") | not) then error("unexpected codexbar output") else . end
    | { source: "codexbar", fetched_at: $now,
        five_hour: (.primary | win),
        seven_day: (.secondary | win),
        seven_day_opus: null, seven_day_sonnet: null, extra_usage: null }' 2>/dev/null
}

raw=""
if [ "$NOCACHE" = 0 ] && [ -f "$CACHE" ]; then
  fetched=$(jq -r '.fetched_at // 0 | floor' "$CACHE" 2>/dev/null) || fetched=0
  if is_num "$fetched" && [ "$fetched" -le "$now" ] && [ $(( now - fetched )) -lt "$CACHE_SECS" ]; then
    raw=$(cat "$CACHE")
  fi
fi
if [ -z "$raw" ]; then
  raw=$(fetch_oauth) || raw=$(fetch_codexbar) || raw=""
  if [ -z "$raw" ]; then
    echo '{"error":"could not fetch usage (no Claude Code OAuth token or the endpoint failed, and codexbar unavailable)"}'
    exit 2
  fi
  # Write atomically: a watcher and a direct check may run at the same time.
  if tmp=$(mktemp "$CACHE.XXXXXX" 2>/dev/null); then
    { printf '%s\n' "$raw" >"$tmp" && mv -f "$tmp" "$CACHE"; } 2>/dev/null || rm -f "$tmp"
  fi
fi

# Add the verdict (driven by the worst window) and seconds_until_reset relative to now, so a
# cached document does not report stale countdowns.
out=$(printf '%s' "$raw" | jq -c --argjson now "$now" --argjson wrap "$WRAP" --argjson block "$BLOCK" '
  def left: if . == null then null
    else . + { seconds_until_reset: (if .resets_epoch == null then null else .resets_epoch - $now end) } end;
  .five_hour |= left | .seven_day |= left | .seven_day_opus |= left | .seven_day_sonnet |= left
  | ([.five_hour, .seven_day, .seven_day_opus, .seven_day_sonnet] | map(select(. != null))) as $wins
  | ($wins | map(.used_pct) | max // 0) as $worst
  | ($wins | map(select(.locked_reason != null)) | length > 0) as $locked
  | ($wins | map(select(.used_pct >= $wrap)) | map(.resets_epoch) | max) as $resume_epoch
  | . + {
      checked_at: ($now | todate),
      worst_used_pct: $worst,
      verdict: (if $locked or $worst >= $block then "blocked"
                elif $worst >= $wrap then "wrap_up" else "ok" end),
      resume_epoch: $resume_epoch,
      resume_buffer_secs: 120 }')

label() { if [ "$1" = - ]; then echo ""; else fmt_epoch "$1" '+%Y-%m-%d %H:%M %Z'; fi; }
IFS=$'\t' read -r fh sd re base buf < <(printf '%s' "$out" | jq -r '
  [.five_hour.resets_epoch, .seven_day.resets_epoch, .resume_epoch,
   (.resume_epoch // .five_hour.resets_epoch), .resume_buffer_secs] | map(. // "-") | @tsv')
out=$(printf '%s' "$out" | jq -c --arg fh "$(label "$fh")" --arg sd "$(label "$sd")" --arg re "$(label "$re")" '
  (if .five_hour then .five_hour.resets_local = $fh else . end)
  | (if .seven_day then .seven_day.resets_local = $sd else . end)
  | .resume_local = $re')

# Ready-made one-shot cron (local time) for resuming: exhausted window's reset (or the 5h reset) + buffer,
# nudged off :00/:30 so it does not land on the top-of-hour thundering herd.
if [ "$base" != - ]; then
  t=$(( base + buf ))
  m=$(fmt_epoch "$t" +%-M); { [ "$m" = 0 ] || [ "$m" = 30 ]; } && t=$((t + 180))
  out=$(printf '%s' "$out" | jq -c --arg cron "$(fmt_epoch "$t" '+%-M %-H %-d %-m *')" \
        --arg loc "$(fmt_epoch "$t" '+%Y-%m-%d %H:%M %Z')" '.resume_cron = $cron | .resume_cron_local = $loc')
fi

if [ "$BRIEF" = 1 ]; then
  printf '%s' "$out" | jq -r '"verdict=\(.verdict)  5h: \(.five_hour.used_pct // "?")% used (resets \(.five_hour.resets_local // "n/a"), in \(((.five_hour.seconds_until_reset // 0)/60)|floor)m)  7d: \(.seven_day.used_pct // "?")% used (resets \(.seven_day.resets_local // "n/a"))" + "  | resume at: \(.resume_cron_local // "n/a") (cron: \(.resume_cron // "n/a"))"'
else
  printf '%s' "$out" | jq .
fi
