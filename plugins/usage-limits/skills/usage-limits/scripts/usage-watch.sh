#!/bin/bash
# Poll usage and exit once the 5-hour window reaches a threshold, or any limit reaches
# wrap_up/blocked. For long autonomous or orchestration jobs: start it with the Bash tool's
# run_in_background: true; its exit wakes the thread so the agent can wrap up in time.
#
# Usage: usage-watch.sh [threshold_pct] [--interval <sec>] [--max-failures <n>]
#   threshold_pct   5-hour used % that ends the watch (default 85)
#   --interval      seconds between checks (default 300)
#   --max-failures  consecutive usage.sh failures before giving up (default 3)
# Env:   USAGE_SH     usage script to call (default: the sibling usage.sh)
# Exit:  0 threshold reached or verdict wrap_up/blocked
#        3 usage.sh failed --max-failures times in a row: usage is unknown, don't fly blind
#        64 bad argument
set -uo pipefail

bad() { echo "usage-watch.sh: $*" >&2; exit 64; }
is_num() { case "$1" in ''|*[!0-9]*) return 1;; esac; }
need_num() { if [ $# -lt 2 ] || ! is_num "$2"; then bad "$1 needs a whole number"; fi; }

U=${USAGE_SH:-$(dirname "$0")/usage.sh}
TH=85; INTERVAL=300; MAXF=3
while [ $# -gt 0 ]; do
  case "$1" in
    --interval) need_num "$@"; INTERVAL=$2; shift 2;;
    --max-failures) need_num "$@"; MAXF=$2; shift 2;;
    *) is_num "$1" || bad "unknown argument: $1"; TH=$1; shift;;
  esac
done
[ "$MAXF" -ge 1 ] || MAXF=1

log() { echo "[$(date '+%H:%M:%S')] $*"; }

fails=0; started=0
while true; do
  if json=$("$U" --no-cache 2>/dev/null); then
    # @tsv fields must never be empty: read collapses adjacent tabs and would shift them.
    IFS=$'\t' read -r pct verdict secs resets resume < <(printf '%s' "$json" | jq -r '
      [(.five_hour.used_pct // 0 | floor), (.verdict // "unknown"), (.five_hour.seconds_until_reset // 0),
       (.five_hour.resets_local // "" | if . == "" then "?" else . end), (.resume_local // "" | if . == "" then "-" else . end)] | @tsv' 2>/dev/null)
    if ! is_num "${pct:-}"; then
      pct=0; verdict=unknown   # malformed output: treat like a failed check below
    fi
    if [ "$verdict" = unknown ]; then
      fails=$(( fails + 1 ))
    elif [ "$pct" -ge "$TH" ] || [ "$verdict" != ok ]; then
      log "usage-watch: triggered, 5h at ${pct}% (threshold ${TH}%), verdict=$verdict"
      echo "seconds_until_reset=$secs (5h resets $resets)"
      [ "$resume" != - ] && echo "binding limit resumes at $resume"
      "$U" --brief   # served from usage.sh's 60s cache
      exit 0
    else
      fails=0
      [ "$started" = 0 ] && log "watching: 5h at ${pct}%, exits at ${TH}%, checks every ${INTERVAL}s"
      started=1
      sleep "$INTERVAL"
      continue
    fi
  else
    fails=$(( fails + 1 ))
  fi
  if [ "$fails" -ge "$MAXF" ]; then
    err=$(printf '%s' "${json:-}" | jq -r '.error // empty' 2>/dev/null)
    log "usage-watch: gave up, usage.sh failed $fails times in a row (${err:-no output}). Usage is unknown."
    exit 3
  fi
  # retry sooner than the normal interval
  sleep $(( INTERVAL < 60 ? INTERVAL : 60 ))
done
