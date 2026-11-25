---
name: fan-out
description: >-
  Take several GitHub issues from plan to merged PRs in parallel. One T3 thread per issue, in its own worktree, runs the whole flow: a planner, a short summary for the user's approval, an implementer, verify, review-loop and ship-it. The coordinator starts the threads, collects the approvals and merges dependencies first. Use when the user names issues to implement ("look at issues 36, 37 and 38", "implement the open issues", "spawn a planner and an implementer for each") or says "fan out". With --plan-only it only posts plans on the issues, for example overnight.
---

# Fan out

You coordinate; one thread per issue does the work. Collect short messages,
not file dumps. Call `orchestrator_capabilities` and take the newest model of
each family, unless the user names others:
- issue threads and implementers: Opus at `high`, or Sonnet for fully
  specified, mechanical work
- planners: Fable at `xhigh`
- reviewers: as `review-loop` picks them

## 1. Gather

- **Read** each issue with `read_issue` (and `link_issue` when working on it),
  or `gh` outside T3, plus the docs that `CLAUDE.md` or `AGENTS.md` marks as
  binding.
- **Check "Done when".** Every issue needs testable criteria. If they're
  missing, draft them. Add them to the issue after the user's OK; in plan-only
  mode, put them in the plan comment instead.
- **Note how the issues interact:**
  - B needs A merged.
  - Two issues edit the same files: run them one after the other.
  - Something can't be shared: benchmarks, GPU measurements, a device, a fixed
    port, migrations.

Keep one issue per thread. Group issues into one thread only when the user
asks.

## 2. Start one thread per issue

In T3, start each thread with `t3_thread_launch`:
- `workspaceStrategy: {type: "worktree", baseRef: "origin/<default>", startFromOrigin: true, branch}`
- `modelSelection` for the issue-thread model
- `delegatedFrom` set to this thread
- a brief written with the `handoff` skill

Only outside T3 (when `t3_thread_launch` isn't available), use one isolated
worktree per issue instead (a worktree subagent, or `git worktree add` plus a
native subagent); each runs the flow directly (without nested subagents or
thread messages) and stops before merging.

Each brief holds:
- the issue, "Done when", and the binding docs
- the user's decisions so far, as "decided, do not reopen"
- the lock script path below
- whether merges are allowed, and whether `--auto` applies
- your thread id
- the issue flow in section 3

**Dependencies.** Launch a dependent issue's thread only after the thread it
depends on reports its merge. Use `baseRef: "origin/<default>"` with
`startFromOrigin: true` so it picks up the merge.

## 3. The issue flow (inside each issue thread)

1. **Plan.** Start a Fable `xhigh` planner with `delegate_task`
   (`role: "design"`, "read only" in the task text). Ask it for the approach,
   the files, the steps, the tests, how to verify, the risks and the open
   questions.
2. **Approve.** Send the coordinator a 5 to 10 sentence summary and the open
   questions with `t3_thread_send`, then end your turn and wait. Go ahead
   when the coordinator passes on the go, or when the user answers in this
   thread. With `--auto`, skip the wait.
3. **Implement.** Start an Opus `high` implementer with `delegate_task`
   (`role: "implementation"`). It works in this thread's worktree. Give it the
   approved plan and the decisions. For a big plan, use several implementers
   one after the other.
4. **Land.** Run `ship-it` on this thread's branch; it proves and reviews
   the work before the PR. This thread owns and watches the PR. Merge only if
   merges are allowed. When the coordinator says several PRs land, skip
   ship-it's install, deploy and live check.
5. **Report.** Send the coordinator the PR URL, the SHA and the state when the
   PR is ready, and again when it has merged.

## 4. Coordinate

- **Approvals.** Wait until all launched threads have sent their plan
  summaries (or note any stalled one), then show the user all of them
  together, with the open questions and the order. On their go, for all issues
  or for each one, pass the go and their decisions to each thread with
  `t3_thread_send`.
- **Shared resources.** Use one lock per resource with the repo's
  `scripts/lock.sh`, or [lock.sh](../../scripts/lock.sh) if the repo doesn't
  have one (`lock.sh gpu -- <bench>`): it waits, names the owner, clears stale
  locks and always releases. Once all threads run, send each the others'
  thread ids so they can warn each other about long holds.
- **Tracking.** Keep a table (issue, thread link, plan, PR, state) and answer
  status questions from it. Follow the threads' messages instead of polling
  them.
- **Finish.** After the last merge, pull main once and run ship-it's install
  or deploy and its live check yourself. Comment on partly done issues with
  `pr-comments`, and list the follow-ups; file them only if the user asks.
  Settle the finished threads, if the user wants that.

## Plan-only

For an overnight run, without threads:
- Start one Fable `xhigh` planner per issue as in step 3.1.
- Plan the open issues that have no plan yet. An issue counts as planned when
  it has a comment starting `## Plan (fan-out)` that is newer than both the
  body's last edit (`lastEditedAt` or `createdAt` if unedited, via
  `gh api graphql`) and its newest other comment. Don't go by `updatedAt`;
  your own plan comment bumps it.
  Skip `blocked` and `draft` issues.
- Post each plan as a comment that starts with that heading and ends with the
  open questions. `--plan-only` is the OK to post these, without an
  attribution note, so the heading stays first.
- Never implement, edit, label or close anything.
- Report what you planned, what you skipped, and why.
