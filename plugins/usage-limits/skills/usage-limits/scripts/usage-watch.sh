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
set -uo pipefail

U=${USAGE_SH:-$(dirname "$0")/usage.sh}
TH=85; INTERVAL=300; MAXF=3
while [ $# -gt 0 ]; do
  case "$1" in
    --interval) INTERVAL=$2; shift 2;;
    --max-failures) MAXF=$2; shift 2;;
    [0-9]*) TH=$1; shift;;
    *) echo "unknown argument: $1" >&2; exit 64;;
  esac
done

log() { echo "[$(date '+%H:%M:%S')] $*"; }

fails=0; started=0
while true; do
  if json=$("$U" --no-cache 2>/dev/null); then
    fails=0
    read -r pct verdict secs < <(jq -r '"\(.five_hour.used_pct // 0 | floor) \(.verdict) \(.five_hour.seconds_until_reset // 0)"' <<<"$json")
    if [ "$pct" -ge "$TH" ] || [ "$verdict" != ok ]; then
      log "usage-watch: triggered, 5h at ${pct}% (threshold ${TH}%), verdict=$verdict"
      echo "seconds_until_reset=$secs (5h resets $(jq -r '.five_hour.resets_local // "?"' <<<"$json"))"
      jq -r 'if .resume_epoch != null then "binding limit resumes at \(.resume_local)" else empty end' <<<"$json"
      "$U" --brief   # served from usage.sh's 60s cache
      exit 0
    fi
    [ "$started" = 0 ] && log "watching: 5h at ${pct}%, exits at ${TH}%, checks every ${INTERVAL}s"
    started=1
    sleep "$INTERVAL"
  else
    fails=$(( fails + 1 ))
    if [ "$fails" -ge "$MAXF" ]; then
      err=$(jq -r '.error // empty' <<<"$json" 2>/dev/null)
      log "usage-watch: gave up, usage.sh failed $fails times in a row (${err:-no output}). Usage is unknown."
      exit 3
    fi
    # retry sooner than the normal interval
    sleep $(( INTERVAL < 60 ? INTERVAL : 60 ))
  fi
done
