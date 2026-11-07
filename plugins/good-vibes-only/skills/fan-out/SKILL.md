---
name: fan-out
description: Take several GitHub issues from plan to merged PRs in parallel. One planner per issue and a short summary for the user's approval. Then one T3 thread per issue, in its own worktree, that implements the issue, reviews it and ships its PR, with dependencies merged first. Use when the user names issues to implement ("look at issues 36, 37 and 38", "implement the open issues", "spawn a planner and an implementer for each") or says "fan out". With --plan-only it only posts plans on the issues, for example overnight.
---

# Fan out

You coordinate; children do the work. Collect short reports, not file dumps.
Call `orchestrator_capabilities` and take the newest model of each family,
unless the user names others:
- planners: Fable at `xhigh`
- implementers: Opus at `high`, or Sonnet for fully specified, mechanical work
- reviewers: as `review-loop` picks them

## 1. Gather

- **Read** each issue with `gh issue view <n> --comments`, and the docs that
  `CLAUDE.md` marks as binding.
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

## 2. Plan and approve

Start one planner per issue with `delegate_task` (`role: "design"`,
`mode: "async"`). Write "read only" into the task text. Ask for the approach,
the files, the steps, the tests, how to verify, the risks and the open
questions.

Show the user 5 to 10 sentences per plan, with the open questions and the
order. Wait for their go unless they said to skip it or passed `--auto`. Pass
their decisions on as "decided, do not reopen".

## 3. One thread per issue

In T3, start one thread per issue with `t3_thread_launch`:
- `workspaceStrategy: {type: "worktree", baseRef: <current default branch>, branch}`
- `delegatedFrom` set to this thread
- `modelSelection` for the implementer model above
- a brief written with the `handoff` skill

Outside T3, use one worktree subagent per issue instead.

Each brief holds:
- the approved plan, and the user's decisions as "decided, do not reopen"
- "Done when"
- the instruction to prove the work with `verify`, then run `review-loop` and
  `ship-it` on its own PR. The thread owns and watches that PR. Tell it to
  merge only if the user allowed merges.
- your thread id, and a request to `t3_thread_send` you the PR URL, the SHA
  and the state when the PR is ready and again when it has merged. A launched
  thread doesn't report back on its own.
- when several PRs land, an instruction to skip ship-it's install, deploy and
  live check; you do those once at the end

**Dependencies.** Launch a dependent issue's thread only after the thread it
depends on reports its merge. Its `baseRef` is the updated default branch.

**Shared resources.** Use one lock for each resource, and put these rules in
every brief, with the exact lock path filled in (such as
`/tmp/pladder-gpu.lock`):
- Take it with `mkdir <lock path>`, with an `owner` file inside naming the
  thread. The `mkdir` decides who goes.
- If it's taken, wait with one background
  `until mkdir <lock path> 2>/dev/null; do sleep 30; done`.
- Release it with `rm -r`, and never break someone else's lock.
- When a thread is stopped or fails, you remove the locks its `owner` file
  names.
- Once all threads run, send each the others' thread ids. They may tell each
  other about long holds.

## 4. Track and finish

Keep a table (issue, thread link, branch, PR, state) and answer status
questions from it. Follow the threads' messages instead of polling them.
Rebasing is each thread's job; ship-it rebases when a PR falls behind. After
the last merge, pull main once and run ship-it's install or deploy and its
live check yourself.

At the end, comment on partly done issues with `pr-comments` and list the
follow-ups. File them only if the user asks. Settle the threads that finished,
if the user wants that.

## Plan-only

For an overnight run:
- Plan the open issues that have no plan yet. An issue counts as planned when
  it has a comment starting `## Plan (fan-out)` that is newer than both the
  body's last edit (`lastEditedAt` through `gh api graphql`) and its newest
  other comment. Don't go by `updatedAt`; your own plan comment bumps it.
  Skip `blocked` and `draft` issues.
- Post each plan as a comment that starts with that heading and ends with the
  open questions. `--plan-only` is the OK to post these, without an
  attribution note, so the heading stays first.
- Never implement, edit, label or close anything.
- Report what you planned, what you skipped, and why.
