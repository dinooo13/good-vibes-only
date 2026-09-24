---
name: usage-limits
description: Check Claude Code subscription usage limits (5-hour and 7-day windows), watch usage in the background during long jobs, and when a limit is close or exhausted, save state, stop cleanly, and wait in the background until the window resets so the same thread wakes up and continues. Use before/during long autonomous or orchestration jobs (especially ones running subagents), when the user asks about usage or limits, or says "watch my usage", "pause until reset", or "wait until the limit resets".
argument: [check | watch | pause]
---

# usage-limits

Scripts live in `~/.claude/skills/usage-limits/scripts/`:

- `usage.sh [--brief] [--no-cache]` prints usage JSON. It calls Anthropic's OAuth usage endpoint with the Claude Code keychain token and falls back to `codexbar`, with a 60s cache. Fields: `verdict` (`ok` / `wrap_up` / `blocked`), `five_hour.{used_pct,seconds_until_reset,resets_local}`, `seven_day.*`, `resume_local` (reset of the window that is exhausted, if any), and `resume_cron_local` (the time to resume: reset + about 2 min). Thresholds: `USAGE_WRAP_PCT` (default 90), `USAGE_BLOCK_PCT` (default 100).
- `usage-watch.sh [threshold] [--interval 300] [--max-failures 3]` polls usage. It exits 0 when 5-hour usage reaches `threshold` (default 85) or the verdict is no longer `ok`, and prints `seconds_until_reset` plus the usage line. It exits 3 if `usage.sh` fails several times in a row.
- `wait-reset.sh [--buffer 120] [--max-sleep 3600]` sleeps until the binding window resets: the 7-day window if that one is exhausted, otherwise the 5-hour window. Then it re-checks usage and keeps waiting while the verdict is still `wrap_up`/`blocked`. It exits 0 with the fresh usage line. If `usage.sh` fails, it falls back to a 30-minute wait, says so, and exits 2 if usage is still unavailable after that. `WAIT_SECS=<n>` is a test override: it just sleeps n seconds.

## How waiting works

Run the watcher and the waiter with the Bash tool's `run_in_background: true`. A background process keeps running after the turn ends. When it exits, the harness sends a task notification that **wakes this same thread**. So a process that just sleeps is a reliable wake-up timer. It costs no tokens while it waits, because it only runs `sleep` and local `usage.sh` calls, not model calls. The one turn after it exits is the only cost.

- Foreground `sleep` is blocked by the harness, so these must always be `run_in_background: true`.
- The process belongs to the session. If the thread or the app is closed, it dies and nothing resumes. Say so when you pause.
- Background **subagents keep running and keep using quota** while the orchestrator waits. A pause stops *new* work. It does not stop agents that are already running.

## Workflow for a long autonomous job

1. **At the start:** run `usage.sh --brief` once. If the verdict is `ok`, start the watcher in the background:
   `~/.claude/skills/usage-limits/scripts/usage-watch.sh 85` (`run_in_background: true`).
   Run only one watcher per session. Remember its task ID. If one is already running, don't start another. `pgrep -fl usage-watch.sh` lists watchers on this machine, including watchers from other sessions. Before starting each large step, you can still run `usage.sh --brief` directly.
   Mention the usage line to the user only when the verdict is not `ok` or when they asked.

2. **When the watcher exits 0, or a check shows `wrap_up`/`blocked`:** wrap up.
   - Finish the current atomic step only. Start no new subagents, builds, or large refactors. Let subagents that are already running finish; don't kill them.
   - Persist state: commit or stash work in progress. Write a short handoff note (done / next / exact next command / which subagents were still running) into the project's existing progress file. If there is none, use `.claude/usage-limits-handoff.md` in the cwd.
   - Start the waiter: `~/.claude/skills/usage-limits/scripts/wait-reset.sh` (`run_in_background: true`).
   - Tell the user the usage numbers and the approximate wake time (`resume at` from the usage line). Say that the app and this thread must stay open. Then **end the turn**.

   If the verdict is `blocked`, do the same, but write only the notes you can write cheaply.

3. **When `wait-reset.sh` exits:**
   - Exit 0: read its output (the fresh usage line) and the handoff note, and check on the subagents that were still running. Continue with the next step, and start a new watcher (step 1). The job can chain across several windows this way.
   - Exit 2 (usage unknown): tell the user, and continue only with small steps while checking `usage.sh` manually.

4. **If the watcher exits 3** (usage unavailable): report it. Don't guess remaining usage. Keep working in small steps and retry `usage.sh --brief` before large ones.

## Rules

- Write the real next step into the handoff note. The waiter's output doesn't include it, so that note is what you resume from.
- Run one watcher and one waiter per session. Stop the watcher (`TaskStop`) before starting the waiter if it's still running, and start a fresh watcher after resuming.
- Never lower the thresholds to keep working. A hard cut-off in the middle of a tool call loses in-flight state; stopping early is the point.
- Never run `sleep` in the foreground or in a polling loop inside the model. The background scripts do the waiting.

## Fallback: CronCreate

Use `CronCreate` only if background Bash is not available. Load it via `ToolSearch`, then call it with `cron` = `resume_cron` from `usage.sh` (a local one-shot) and `recurring: false`. Put the concrete next step in the prompt. Check `CronList` first so that only one job exists. Cron jobs are in-memory and die with the session too.

## Direct invocations

- `/usage-limits` or `/usage-limits check`: run `usage.sh --brief` and report.
- `/usage-limits watch [pct]`: start `usage-watch.sh [pct]` in the background (step 1).
- `/usage-limits pause`: do step 2 now, then wait for the reset.
