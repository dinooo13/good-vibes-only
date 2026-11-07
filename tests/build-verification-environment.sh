#!/bin/bash
# shellcheck disable=SC2015
# Offline tests for build-verification-environment's lock.sh. Locks live in a temp dir.
#
# Usage: tests/build-verification-environment.sh
set -uo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
L=$ROOT/plugins/good-vibes-only/skills/build-verification-environment/scripts/lock.sh
T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT

export LOCK_ROOT=$T/locks LOCK_POLL=0.2
mkdir -p "$LOCK_ROOT"

pass=0; fail=0
ok()  { pass=$((pass + 1)); echo "ok   $1"; }
nok() { fail=$((fail + 1)); echo "FAIL $1"; [ -n "${2:-}" ] && printf '%s\n' "$2" | sed 's/^/     /'; }
expect() { local name=$1 want=$2; shift 2; "$@" >"$T/out" 2>&1; local got=$?
  if [ "$got" = "$want" ]; then ok "$name"; else nok "$name" "exit $got, want $want: $(cat "$T/out")"; fi; }

# A repo with a worktree, so the lock name comes from the main checkout.
git init -q "$T/myrepo" && git -C "$T/myrepo" -c user.name=t -c user.email=t@t commit -q --allow-empty -m init
git -C "$T/myrepo" worktree add -q "$T/wt" -b wt 2>/dev/null
cd "$T/myrepo" || exit 1
LOCK=$LOCK_ROOT/myrepo-gpu.lock

expect "--help exits 0" 0 "$L" --help
grep -q "Usage: scripts/lock.sh" "$T/out" && ok "--help prints usage" || nok "--help prints usage" "$(cat "$T/out")"
expect "no args exits non-zero" 1 "$L"
expect "no command exits 2" 2 "$L" gpu
expect "bad resource exits 2" 2 "$L" "../x" -- true
expect "status free" 0 "$L" --status gpu

expect "runs the command" 0 "$L" gpu -- sh -c 'echo ran'
grep -q '^ran$' "$T/out" && ok "command output passes through" || nok "command output passes through" "$(cat "$T/out")"
[ ! -e "$LOCK" ] && ok "released after success" || nok "released after success"

expect "passes the exit code through" 7 "$L" gpu -- sh -c 'exit 7'
[ ! -e "$LOCK" ] && ok "released after failure" || nok "released after failure"

expect "works without --" 0 "$L" gpu true

# Held while the command runs, with the owner named.
LOCK_OWNER="thread-a" "$L" gpu -- sh -c "touch '$T/started'; sleep 1" 2>/dev/null &
holder=$!
for _ in $(seq 50); do [ -e "$T/started" ] && break; sleep 0.1; done
expect "status held" 1 "$L" --status gpu
grep -q "thread-a" "$T/out" && ok "status names the owner" || nok "status names the owner" "$(cat "$T/out")"

# A second caller from the worktree waits for the same lock, then runs.
start=$(date +%s)
(cd "$T/wt" && "$L" gpu -- sh -c 'echo second') >"$T/second" 2>&1
grep -q "waiting for $LOCK, held by: thread-a" "$T/second" && ok "worktree shares the lock and waits" \
  || nok "worktree shares the lock and waits" "$(cat "$T/second")"
grep -q '^second$' "$T/second" && ok "waiter runs after release" || nok "waiter runs after release" "$(cat "$T/second")"
wait "$holder"
[ ! -e "$LOCK" ] && ok "released after both" || nok "released after both"
[ $(( $(date +%s) - start )) -lt 10 ] && ok "no long stall" || nok "no long stall"

# TERM stops the command too, then releases the lock.
"$L" gpu -- sh -c "echo \$\$ >'$T/child'; exec sleep 30" 2>/dev/null &
holder=$!
for _ in $(seq 50); do [ -s "$T/child" ] && break; sleep 0.1; done
kill -TERM "$holder"; wait "$holder"; rc=$?
[ "$rc" = 143 ] && ok "TERM exits 143" || nok "TERM exits 143" "exit $rc"
kill -0 "$(cat "$T/child")" 2>/dev/null && nok "TERM stops the command" || ok "TERM stops the command"
[ ! -e "$LOCK" ] && ok "released after TERM" || nok "released after TERM"

# stdin reaches the command.
out=$(echo piped | "$L" gpu -- cat 2>/dev/null)
[ "$out" = piped ] && ok "stdin passes through" || nok "stdin passes through" "$out"

echo "$pass passed, $fail failed"
[ "$fail" = 0 ]
