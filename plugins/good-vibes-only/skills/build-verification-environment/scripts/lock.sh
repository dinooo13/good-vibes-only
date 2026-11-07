#!/bin/bash
# One at a time on shared hardware. Agents running in parallel on the same
# machine take turns, so a benchmark never measures another agent's load.
#
# Usage: scripts/lock.sh <resource> [--] <command> [args...]
#        scripts/lock.sh --status <resource>
#
# The lock is the directory /tmp/<repo>-<resource>.lock; mkdir decides who
# goes. An `owner` file inside names the holder. Worktrees of one repo share
# the lock. The lock is released when the command ends, also on failure or
# Ctrl-C, and the command's exit code is passed through.
#
# Env: LOCK_OWNER  who holds it (default: user@host pid N in <dir>)
#      LOCK_POLL   seconds between tries while waiting (default 30)
#      LOCK_ROOT   where locks live (default /tmp)
set -uo pipefail

usage() { sed -n '2,15p' "$0" | sed 's/^# \{0,1\}//'; }

case "${1:-}" in
  -h|--help|'') usage; [ -n "${1:-}" ]; exit $? ;;
esac

status=0
if [ "$1" = --status ]; then status=1; shift; fi
resource=${1:-}
[ -n "$resource" ] || { usage >&2; exit 2; }
shift
case "$resource" in
  *[!A-Za-z0-9._-]*) echo "lock.sh: resource must be letters, digits, . _ or -" >&2; exit 2 ;;
esac

common=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null) || common=$PWD/.git
repo=$(basename "$(dirname "$common")")
lock="${LOCK_ROOT:-/tmp}/$repo-$resource.lock"

if [ "$status" = 1 ]; then
  if [ -d "$lock" ]; then echo "held: $(cat "$lock/owner" 2>/dev/null || echo unknown)"; exit 1; fi
  echo "free: $lock"; exit 0
fi

[ "${1:-}" = -- ] && shift
[ $# -gt 0 ] || { echo "lock.sh: no command given" >&2; exit 2; }

owner="${LOCK_OWNER:-$(id -un)@$(hostname -s) pid $$ in $PWD} since $(date '+%F %T')"
said=
until mkdir "$lock" 2>/dev/null; do
  if [ -z "$said" ]; then
    echo "lock.sh: waiting for $lock, held by: $(cat "$lock/owner" 2>/dev/null || echo unknown)" >&2
    said=1
  fi
  sleep "${LOCK_POLL:-30}"
done
printf '%s\n' "$owner" >"$lock/owner"
trap 'rm -rf "$lock"' EXIT
echo "lock.sh: took $lock" >&2

# Run the command as a child so a signal stops it before the lock goes.
"$@" <&0 &
child=$!
trap 'kill -INT "$child" 2>/dev/null; wait "$child"; exit 130' INT
trap 'kill -TERM "$child" 2>/dev/null; wait "$child"; exit 143' TERM
wait "$child"
