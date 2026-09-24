#!/bin/bash
# Sleep until the binding usage window has reset, then print the fresh usage line and exit.
# Start it with the Bash tool's run_in_background: true. When it exits, the harness wakes the
# thread that started it. Costs no tokens while waiting (sleep + local usage.sh calls only).
#
# Which reset: the latest reset among windows at/above USAGE_WRAP_PCT (usage.sh's resume_epoch,
# e.g. the 7-day window when that is the one exhausted), otherwise the 5-hour reset.
# Sleeps in chunks of at most --max-sleep and re-checks the wall clock, because macOS `sleep`
# does not count time while the machine is asleep. After the reset it re-checks usage and keeps
# waiting while the verdict is still wrap_up/blocked.
#
# Usage: wait-reset.sh [--buffer <sec>] [--max-sleep <sec>]
#   --buffer     seconds to wait past the reset (default 120)
#   --max-sleep  longest single sleep before re-checking the clock (default 3600)
# Env:   WAIT_SECS           test: sleep exactly this long, print usage, exit 0
#        WAIT_FALLBACK_SECS  wait used when usage.sh fails on the first check (default 1800)
#        USAGE_SH            usage script to call (default: the sibling usage.sh)
# Exit:  0 reset reached and verdict ok (or nothing to wait for)
#        2 usage still unavailable after the fallback wait
set -uo pipefail

U=${USAGE_SH:-$(dirname "$0")/usage.sh}
BUFFER=120; MAX_SLEEP=3600; FALLBACK=${WAIT_FALLBACK_SECS:-1800}
while [ $# -gt 0 ]; do
  case "$1" in
    --buffer) BUFFER=$2; shift 2;;
    --max-sleep) MAX_SLEEP=$2; shift 2;;
    *) echo "unknown argument: $1" >&2; exit 64;;
  esac
done

log() { echo "[$(date '+%H:%M:%S')] $*"; }
fmt() { date -r "$1" '+%Y-%m-%d %H:%M %Z'; }

if [ -n "${WAIT_SECS:-}" ]; then
  log "test mode: sleeping ${WAIT_SECS}s (WAIT_SECS)"
  sleep "$WAIT_SECS"
  log "wait-reset: done (test mode)"
  "$U" --no-cache --brief
  exit 0
fi

first=1; deadline=""
while true; do
  now=$(date +%s)
  if [ -n "$deadline" ] && [ "$now" -lt "$deadline" ]; then
    s=$(( deadline - now )); [ "$s" -gt "$MAX_SLEEP" ] && s=$MAX_SLEEP
    sleep "$s"; continue
  fi

  if ! json=$("$U" --no-cache 2>/dev/null); then
    err=$(jq -r '.error // empty' <<<"$json" 2>/dev/null); [ -n "$err" ] || err=${json:-"usage.sh failed"}
    if [ "$first" = 1 ]; then
      first=0; deadline=$(( now + FALLBACK ))
      log "usage.sh failed ($err). Falling back to a fixed $(( FALLBACK / 60 ))-minute wait, until $(fmt "$deadline")."
      continue
    fi
    log "wait-reset: gave up, usage still unavailable after waiting ($err). Check usage before continuing."
    exit 2
  fi

  verdict=$(jq -r .verdict <<<"$json")
  if [ "$first" = 0 ] && [ "$verdict" = ok ]; then
    log "wait-reset: done, window reset, verdict ok"
    "$U" --brief   # served from usage.sh's 60s cache
    exit 0
  fi

  read -r target label < <(jq -r '(.resume_epoch // .five_hour.resets_epoch) as $t
    | if $t == null then "none none"
      else "\($t) \(if $t == .five_hour.resets_epoch then "5-hour"
                    elif $t == .seven_day.resets_epoch then "7-day" else "weekly-model" end)" end' <<<"$json")
  if [ "$target" = none ]; then
    if [ "$verdict" = ok ]; then
      log "wait-reset: done, no active usage window to wait for, verdict ok"
      "$U" --brief
      exit 0
    fi
    deadline=$(( now + FALLBACK ))
    log "verdict=$verdict but no reset time reported. Re-checking in $(( FALLBACK / 60 ))m, at $(fmt "$deadline")."
  else
    deadline=$(( target + BUFFER ))
    # reset already passed but the endpoint has not caught up yet: re-check soon
    [ "$deadline" -le "$now" ] && deadline=$(( now + 300 ))
    log "waiting for the $label reset: wake at $(fmt "$deadline") (in $(( (deadline - now) / 60 ))m), verdict now $verdict"
  fi
  [ "$first" = 1 ] && "$U" --brief
  first=0
done
