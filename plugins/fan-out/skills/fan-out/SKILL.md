---
name: fan-out
description: Take several GitHub issues from plan to merged PRs in parallel. One planner per issue, a short summary for the user's approval, one implementer per worktree, then review-loop and ship-it for each PR, merged in order. Use when the user names issues to implement ("look at issues 36, 37 and 38", "implement the open issues", "spawn a planner and an implementer for each") or says "fan out". With --plan-only it only posts plans on the issues, for example overnight.
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
  - Two issues edit the same files: group them or run them one after the
    other.
  - Something can't be shared: benchmarks, GPU measurements, a device, a fixed
    port, migrations.
- **Group** small related issues so you start fewer agents.

## 2. Plan and approve

Start one planner per package with `delegate_task` (`role: "design"`,
`mode: "async"`). Write "read only" into the task text. Ask for the approach,
the files, the steps, the tests, how to verify, the risks and the open
questions.

Show the user 5 to 10 sentences per plan, with the open questions and the
order. Wait for their go unless they said to skip it or passed `--auto`. Pass
their decisions on as "decided, do not reopen".

## 3. Implement

Use one worktree per package.

- **Short work:** `delegate_task` (`role: "implementation"`,
  `isolation: "worktree"`). The worktree starts from your own commit, so first
  pull or rebase onto the current main. The child commits on a named branch
  and pushes it, and you open the PR with `gh pr create --head <branch>`.
- **Long work, or work that needs the user:** start a T3 thread with
  `t3_thread_launch` and `workspaceStrategy: {type: "worktree", baseRef, branch}`,
  with a brief written by the `handoff` skill. A launched thread doesn't report
  back on its own. Give it your thread id and ask it to `t3_thread_send` you
  the PR URL, the SHA and the state when the PR is ready and again when it
  has merged. When several PRs land, tell it to skip ship-it's install,
  deploy and live check; you do those once at the end.

**Dependencies.** Start a dependent package only after its dependency has
merged, then branch it from the updated main. Only the thread that owns a PR
watches it.

**Shared resources.** Use one lock for each resource, and put these rules in
every child's task text:
- Take it with `mkdir /tmp/<repo>-<resource>.lock`, with an `owner` file
  inside. The `mkdir` decides who goes.
- If it's taken, wait with one background
  `until mkdir … 2>/dev/null; do sleep 30; done`.
- Release it with `rm -r`, and never break someone else's lock.
- Once all children run, send each the others' thread ids. They may tell each
  other about long holds.

## 4. Review, ship, track

Run every PR through `review-loop`, then `ship-it`. For a PR from a
short-work child, point the reviewer at the child's branch:
`git diff <base>..origin/<branch>` after a fetch, or the child's worktree
from `t3_worktree_list`.

Merge in dependency order. Each remaining PR's owner rebases it when it falls
behind; ship-it does that. You rebase only the PRs you own. Install or deploy
once, from the final main.

Keep a table (issue, owner, branch, PR, state) and answer status questions
from it. Follow notifications instead of polling. Cancel children you no
longer need with `task_cancel`. At the end, comment on partly done issues and
list the follow-ups. File them only if the user asks.

## Plan-only

For an overnight run:
- Plan the open issues that have no plan yet. An issue counts as planned when
  it has a comment starting `## Plan (fan-out)` that is newer than both the
  body's last edit (`lastEditedAt` through `gh api graphql`) and its newest
  other comment. Don't go by `updatedAt`; your own plan comment bumps it.
  Skip `blocked` and `draft` issues.
- Post each plan as a comment that starts with that heading and ends with the
  open questions.
- Never implement, edit, label or close anything.
- Report what you planned, what you skipped, and why.
