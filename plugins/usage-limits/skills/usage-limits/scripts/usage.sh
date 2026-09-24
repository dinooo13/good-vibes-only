#!/bin/bash
# Print Claude Code subscription usage (5-hour + 7-day windows) as normalized JSON.
# Source order: Anthropic OAuth usage endpoint (token from the Claude Code keychain item),
# then `codexbar usage --provider claude --format json` as fallback.
#
# Usage: usage.sh [--brief] [--no-cache]
# Env:   USAGE_WRAP_PCT   (default 90)  -> verdict "wrap_up" at/above this
#        USAGE_BLOCK_PCT  (default 100) -> verdict "blocked" at/above this
#        USAGE_CACHE_SECS (default 60)
set -euo pipefail

WRAP=${USAGE_WRAP_PCT:-90}
BLOCK=${USAGE_BLOCK_PCT:-100}
CACHE_SECS=${USAGE_CACHE_SECS:-60}
CACHE=~/.claude/usage-limits/cache.json
BRIEF=0; NOCACHE=0
for a in "$@"; do case "$a" in --brief) BRIEF=1;; --no-cache) NOCACHE=1;; esac; done
mkdir -p "$(dirname "$CACHE")"

now=$(date +%s)

fetch_oauth() {
  local tok
  tok=$(security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null \
        | jq -r '.claudeAiOauth.accessToken // empty' 2>/dev/null) || true
  [ -n "$tok" ] || return 1
  local body code
  body=$(curl -s -m 15 -w '\n%{http_code}' \
    -H "Authorization: Bearer $tok" -H "anthropic-beta: oauth-2025-04-20" \
    "https://api.anthropic.com/api/oauth/usage") || return 1
  code=${body##*$'\n'}; body=${body%$'\n'*}
  [ "$code" = "200" ] || return 1
  # normalize
  jq -c --argjson now "$now" '
    def ep: if . == null then null else (sub("\\.[0-9]+";"") | sub("\\+00:00$";"Z") | fromdateiso8601) end;
    def win: if . == null then null else {
      used_pct: (.utilization // 0),
      resets_at: .resets_at,
      resets_epoch: (.resets_at | ep),
      seconds_until_reset: (if .resets_at == null then null else ((.resets_at | ep) - $now) end),
      locked_reason: .locked_reason } end;
    { source: "oauth",
      five_hour: (.five_hour | win),
      seven_day: (.seven_day | win),
      seven_day_opus: (.seven_day_opus | win),
      seven_day_sonnet: (.seven_day_sonnet | win),
      extra_usage: (.extra_usage // null) }' <<<"$body"
}

fetch_codexbar() {
  command -v codexbar >/dev/null || return 1
  local body
  body=$(codexbar usage --provider claude --format json 2>/dev/null) || return 1
  jq -c --argjson now "$now" '
    def ep: if . == null then null else (sub("\\.[0-9]+";"") | sub("\\+00:00$";"Z") | fromdateiso8601) end;
    def win: if . == null then null else {
      used_pct: (.usedPercent // 0),
      resets_at: .resetsAt,
      resets_epoch: (.resetsAt | ep),
      seconds_until_reset: (if .resetsAt == null then null else ((.resetsAt | ep) - $now) end),
      locked_reason: null } end;
    .[0].usage | { source: "codexbar",
      five_hour: (.primary | win),
      seven_day: (.secondary | win),
      seven_day_opus: null, seven_day_sonnet: null, extra_usage: null }' <<<"$body"
}

raw=""
if [ "$NOCACHE" = 0 ] && [ -f "$CACHE" ]; then
  age=$(( now - $(stat -f %m "$CACHE") ))
  [ "$age" -lt "$CACHE_SECS" ] && raw=$(cat "$CACHE")
fi
if [ -z "$raw" ]; then
  raw=$(fetch_oauth) || raw=$(fetch_codexbar) || { echo '{"error":"could not fetch usage (no keychain token / endpoint failed, and codexbar unavailable)"}'; exit 2; }
  printf '%s' "$raw" > "$CACHE"
fi

# Add verdict + local-time strings. Verdict is driven by the worst window.
out=$(jq -c --argjson now "$now" --argjson wrap "$WRAP" --argjson block "$BLOCK" '
  def wins: [.five_hour, .seven_day, .seven_day_opus, .seven_day_sonnet] | map(select(. != null));
  (wins | map(.used_pct) | max // 0) as $worst
  | (wins | map(select(.locked_reason != null)) | length > 0) as $locked
  | (wins | map(select(.used_pct >= $wrap)) | map(.resets_epoch) | max) as $resume_epoch
  | . + {
      checked_at: ($now | todate),
      worst_used_pct: $worst,
      verdict: (if $locked or $worst >= $block then "blocked"
                elif $worst >= $wrap then "wrap_up" else "ok" end),
      resume_epoch: $resume_epoch,
      resume_buffer_secs: 120 }' <<<"$raw")

# local time labels (macOS date -r)
fmt() { [ -n "$1" ] && [ "$1" != "null" ] && date -r "$1" "+%Y-%m-%d %H:%M %Z" || echo ""; }
fh=$(jq -r '.five_hour.resets_epoch // empty' <<<"$out"); sd=$(jq -r '.seven_day.resets_epoch // empty' <<<"$out"); re=$(jq -r '.resume_epoch // empty' <<<"$out")
out=$(jq -c --arg fh "$(fmt "$fh")" --arg sd "$(fmt "$sd")" --arg re "$(fmt "$re")" '
  .five_hour.resets_local = $fh | .seven_day.resets_local = $sd | .resume_local = $re' <<<"$out")

# Ready-made one-shot cron (local time) for resuming: exhausted window's reset (or the 5h reset) + buffer,
# nudged off :00/:30 so it does not land on the top-of-hour thundering herd.
base=$(jq -r '(.resume_epoch // .five_hour.resets_epoch // empty)' <<<"$out")
if [ -n "$base" ]; then
  t=$(( base + $(jq -r .resume_buffer_secs <<<"$out") ))
  m=$(date -r "$t" +%-M); { [ "$m" = 0 ] || [ "$m" = 30 ]; } && t=$((t + 180))
  out=$(jq -c --arg cron "$(date -r "$t" '+%-M %-H %-d %-m *')" --arg loc "$(date -r "$t" '+%Y-%m-%d %H:%M %Z')" \
        '.resume_cron = $cron | .resume_cron_local = $loc' <<<"$out")
fi

if [ "$BRIEF" = 1 ]; then
  jq -r '"verdict=\(.verdict)  5h: \(.five_hour.used_pct // "?")% used (resets \(.five_hour.resets_local), in \(((.five_hour.seconds_until_reset // 0)/60)|floor)m)  7d: \(.seven_day.used_pct // "?")% used (resets \(.seven_day.resets_local))" + "  | resume at: \(.resume_cron_local // "n/a") (cron: \(.resume_cron // "n/a"))"' <<<"$out"
else
  jq . <<<"$out"
fi
