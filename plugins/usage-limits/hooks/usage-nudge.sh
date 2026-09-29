#!/bin/bash
# Claude Code hook (PostToolUse, UserPromptSubmit). The model can't notice time or quota passing,
# so this checks usage every now and then and, when a limit gets close, tells it to load the
# usage-limits skill. Silent while usage is fine, when usage is unknown, and inside subagents
# (the main thread decides when to pause). It never blocks anything: it always exits 0.
#
# It stays fast because it never waits on the network. Most calls exit on the interval check.
# A real check reads usage.sh's cache, and when the cache is over a minute old it starts a
# detached usage.sh that refreshes it for the next check. So decisions can lag by one interval.
#
# Reads the hook input JSON on stdin; prints hookSpecificOutput JSON when it has something to say.
# Each level is announced once per session (heads-up, wrap up, blocked); wrap-up and blocked
# nudges repeat every USAGE_HOOK_REMIND seconds while they last.
#
# Env: USAGE_HOOK           0 turns the hook off
#      USAGE_HOOK_INTERVAL  min seconds between checks per session (default 120)
#      USAGE_HOOK_WARN_PCT  5-hour % for a heads-up (default 75); any window within 5 points of
#                           the wrap-up % gets one too
#      USAGE_WRAP_PCT       % of any window to wrap up at (default 90, shared with usage.sh and
#                           usage-watch.sh: the hook follows usage.sh's wrap_up verdict)
#      USAGE_HOOK_REMIND    seconds before a wrap-up nudge repeats (default 600)
#      USAGE_STALE_SECS     oldest cached result to act on (default 900, same as usage.sh)
#      USAGE_SH             usage script to call (default: the skill's usage.sh)
set -uo pipefail
umask 077

[ "${USAGE_HOOK:-1}" = 0 ] && exit 0

is_num() { case "$1" in ''|*[!0-9]*) return 1;; esac; }
# A hook must not fail over a bad setting, so those fall back to the default.
num() { if is_num "$1"; then echo "$1"; else echo "$2"; fi; }
INTERVAL=$(num "${USAGE_HOOK_INTERVAL:-}" 120)
WARN=$(num "${USAGE_HOOK_WARN_PCT:-}" 75)
WRAP=$(num "${USAGE_WRAP_PCT:-}" 90)
REMIND=$(num "${USAGE_HOOK_REMIND:-}" 600)
MAXAGE=$(num "${USAGE_STALE_SECS:-}" 900)
U=${USAGE_SH:-$(dirname "$0")/../skills/usage-limits/scripts/usage.sh}

# @tsv fields must never be empty: read collapses adjacent tabs and would shift them.
IFS=$'\t' read -r event sid agent < <(jq -r '
  [.hook_event_name, .session_id, .agent_id] | map(. // "" | tostring | if . == "" then "-" else . end) | @tsv' 2>/dev/null)
case "${event:-}" in PostToolUse|UserPromptSubmit) ;; *) exit 0;; esac
[ "${agent:-}" = - ] || exit 0

sid=$(printf '%s' "$sid" | tr -cd 'A-Za-z0-9_-' | cut -c1-80)
DIR=${CLAUDE_CONFIG_DIR:-$HOME/.claude}/usage-limits
STATE=$DIR/hook-${sid:-default}   # "<last check epoch> <last level> <last nudge epoch>"
mkdir -p "$DIR" 2>/dev/null || exit 0
now=$(date +%s)

checked=0 level=0 nudged=0
[ -f "$STATE" ] && read -r checked level nudged <"$STATE" 2>/dev/null
is_num "${checked:-}" && [ "$checked" -le "$now" ] || checked=0
is_num "${level:-}" || level=0
is_num "${nudged:-}" && [ "$nudged" -le "$now" ] || nudged=0

save() { { printf '%s %s %s\n' "$1" "$2" "$3" >"$STATE.$$" && mv -f "$STATE.$$" "$STATE"; } 2>/dev/null || rm -f "$STATE.$$"; }

[ $(( now - checked )) -lt "$INTERVAL" ] && exit 0
save "$now" "$level" "$nudged"
if [ "$event" = UserPromptSubmit ]; then
  find "$DIR" -name 'hook-*' -mtime +2 -delete 2>/dev/null   # state of long-gone sessions
fi

# usage.sh's cache (see CACHE there). Refresh it in the background when it is over a minute old,
# at most once a minute across all sessions.
CACHE=$DIR/usage-cache.json
fetched=$(jq -r '.fetched_at // 0 | floor' "$CACHE" 2>/dev/null) || fetched=0
is_num "${fetched:-}" && [ "$fetched" -le "$now" ] || fetched=0
age=$(( now - fetched ))
if [ "$age" -ge 60 ] && [ -z "$(find "$DIR/refresh-started" -mmin -1 2>/dev/null)" ]; then
  touch "$DIR/refresh-started"
  nohup "$U" </dev/null >/dev/null 2>&1 &
fi
[ "$age" -lt "$MAXAGE" ] || exit 0   # nothing recent to go on yet: the next check will have it

# Served from the cache: usage.sh only fetches when the cache is older than USAGE_CACHE_SECS.
export USAGE_CACHE_SECS=$(( MAXAGE + 60 ))
json=$("$U" 2>/dev/null) || exit 0   # usage unknown: stay quiet, the skill handles that case
IFS=$'\t' read -r verdict pct worst < <(printf '%s' "$json" | jq -r '
  [(.verdict // "unknown"), (.five_hour.used_pct // 0 | floor), (.worst_used_pct // 0 | floor)] | @tsv' 2>/dev/null)
is_num "${pct:-}" && is_num "${worst:-}" || exit 0
case "$verdict" in
  blocked) new=3;;
  wrap_up) new=2;;
  ok) if [ "$pct" -ge "$WARN" ] || [ "$worst" -ge $(( WRAP - 5 )) ]; then new=1; else new=0; fi;;
  *) exit 0;;
esac

if [ "$new" -gt "$level" ] || { [ "$new" -ge 2 ] && [ $(( now - nudged )) -ge "$REMIND" ]; }; then
  brief=$("$U" --brief 2>/dev/null) || brief="5h at ${pct}%, verdict=$verdict"
  case "$new" in
    1) msg="Usage is getting high (5-hour window at ${pct}%, highest window at ${worst}%). If more than a few steps of work remain, load the usage-limits skill and start its watcher (usage-watch.sh) unless one is already running. Check usage before starting any large step.";;
    2) msg="Usage is close to the limit. Load the usage-limits skill now and follow its wrap-up step: finish only the current step, start no new subagents or large steps, commit, write the handoff note, start wait-reset.sh in the background, tell the user, and end the turn.";;
    3) msg="A usage limit is reached. Load the usage-limits skill now and follow its wrap-up step with as little work as possible: save state, start wait-reset.sh in the background, tell the user, and end the turn.";;
  esac
  jq -nc --arg e "$event" --arg c "usage-limits: $brief"$'\n'"$msg" \
    '{hookSpecificOutput: {hookEventName: $e, additionalContext: $c}}'
  nudged=$now
fi
save "$now" "$new" "$nudged"
exit 0
