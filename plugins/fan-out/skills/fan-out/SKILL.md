---
name: fan-out
description: Take several GitHub issues from plan to merged PRs in parallel. One planner per issue, a short summary of each plan for the user's approval, one implementer per worktree, then review-loop and ship-it for each PR, merged in dependency order. Use when the user names issues to implement ("look at issues 36, 37 and 38", "implement the open issues", "spawn a planner and an implementer for each"), or says "fan out". With "--plan-only" it only drafts plans and posts them on the issues, for example in an overnight scheduled task.
---

# Fan out

You are the coordinator. Planners, implementers and reviewers do the work; you
keep track, keep them apart, and keep the user's decisions. Keep your own
context small: collect short reports, not file dumps.

Work in T3 Code with T3's tools. Outside T3, use the harness's subagent tools
and say what you used.

## Models

Call `orchestrator_capabilities` once. Resolve the newest model of each family;
never hardcode IDs. Defaults, unless the user names others:

| Role | Model |
| --- | --- |
| Planner | newest Claude Fable, `xhigh` |
| Implementer, judgement needed | newest Claude Opus, `high` |
| Implementer, fully specified and mechanical | newest Claude Sonnet, `medium` |
| Explorer, quick lookups | newest Claude Sonnet or Haiku, `medium` |
| Reviewer | as the `review-loop` skill picks |

Use `xhigh` for implementers only on small, hard pieces.

## 0. Gather

1. Read every issue in full with its comments: `gh issue view <n> --comments`.
2. Read `CLAUDE.md`, `AGENTS.md` and the docs they name as binding.
3. **Check "Done when".** Each issue needs acceptance criteria that can be
   tested. If they are missing or vague, draft them. Add them to the issue
   faithfully once the user approves, or straight away in auto mode. In
   plan-only mode, put them into the plan comment and leave the issue alone.
4. **Find links between issues.**
   - Dependencies: B needs A merged.
   - Shared files: two issues that edit the same files become one package, or
     run one after the other.
   - Shared resources that cannot run in parallel: benchmarks, GPU or Neural
     Engine measurements, a physical device, a fixed dev-server port,
     database migrations.
5. **Group** small related issues into packages so you start fewer agents.
   The user cares about this.

## 1. Plan

Start one planner per package with `delegate_task`:
- `role: "design"`, `mode: "async"`
- the newest Fable at `xhigh`
- "Read only: do not edit, commit or push" written into the task text, since
  `delegate_task` has no read-only flag

The brief holds:
- the issue text, or tell the planner to run `gh issue view`
- the binding docs
- the shared-resource constraints
- the output you want: approach, files to change, steps, tests, how to verify
  (including UI), risks, open questions, and a size estimate

Do not poll. Collect the reports as their notifications arrive.

## 2. Approval gate

Show the user, for each package:
- a summary of 5 to 10 sentences
- open questions, with your recommendation
- dependencies and order

Wait for their go. Skip the gate only when the user said so ("go ahead, you
don't need my approval") or passed `--auto`. Record their decisions; you will
pass them on as "decided, do not reopen".

## 3. Implement

Use one worktree per package. Pick the vehicle by size:

- **Short, self-contained work:** use `delegate_task` with
  `role: "implementation"` and `isolation: "worktree"`. That worktree starts
  from your own checkout's commit, not from origin. So first bring your
  checkout to the current default branch: `git pull --ff-only` in the root
  checkout, or rebase your worktree. Tell the child to commit on a named
  branch and push it (`git push -u origin <branch>`). Then you open the PR
  with `gh pr create --head <branch>`.
- **Long work, or work that will need the user's input or its own PR
  babysitting:** start a T3 thread with `t3_thread_launch`, using
  `workspaceStrategy: {type: "worktree", baseRef: "<base>", branch: "<name>"}`.
  Write the brief with the `handoff` skill. Tell the thread to open its PR and
  run `ship-it` up to "ready", or to merge if the user wants that.
  - A launched thread does not report back to you on its own. In the brief,
    give it your thread id and tell it to call `t3_thread_send` to you when
    its PR is ready and again when it has merged, with the PR URL, the head or
    merge SHA, and the state. Then end your turn; that message wakes you.
  - When several packages merge, tell each thread to skip ship-it's
    install/deploy and live-check steps (5.2 and 5.3). You do them once at the
    end.

Every brief includes:
- the approved plan
- the user's decisions, as "decided, do not reopen"
- the binding docs
- how to verify
- "Done when"
- the coordination rules below

**Dependencies.** Do not start a package before the packages it depends on
have merged. Only the thread that owns a PR watches it. You learn about the
merge from that thread's message, or, for PRs you own, from your own
`watch_pull_request`. After the merge, update your checkout to the new main
and start the next package from there.

**Shared resources.** Give every child the same lock protocol:
1. Take the lock with `mkdir /tmp/<repo>-<resource>.lock`, and write your
   name and the time into an `owner` file inside it. The `mkdir` is the gate.
2. If it fails, the resource is busy. Wait for it with one background
   command: `until mkdir /tmp/<repo>-<resource>.lock 2>/dev/null; do sleep 30; done`
   with `run_in_background`, then `t3_background_wait`.
3. Release it with `rm -r` when done. Never break someone else's lock.
4. Once all children are running, send each the others' thread ids. They may
   tell each other when they take or release a lock, as a courtesy for long
   holds.

## 4. Review and ship

- Each PR goes through the `review-loop` skill.
- Then `ship-it`. Merge in dependency order, and rebase the remaining PRs after
  each merge.
- When several PRs land together, install or deploy once at the end, from the
  final main, not once per PR. Run ship-it's steps 5 and 6 yourself after the
  last merge.

## 5. Track

Keep one table and answer status questions from it, without waking children:

| Issue | Package | Owner (task or thread) | Branch | PR | State |
| --- | --- | --- | --- | --- | --- |

Follow notifications; do not poll. Cancel children you no longer need with
`task_cancel`. For a long run, load the `usage-limits` skill if it is
installed.

## 6. Wrap up

- Issues close through their PRs (`Closes #N`). On issues that are only partly
  done, comment with what's done and what's left.
- List the follow-ups found along the way. File them as issues only if the
  user asked for that, or asks now.
- Settle child threads that are finished, if the user wants that.
- Report the table, the merged PRs, what was installed or deployed, and the
  follow-ups.

## Plan-only mode

For an unattended or overnight run (`--plan-only`):

1. Find open issues that have no current plan. A current plan is a comment
   starting with `## Plan (fan-out)` that is newer than the issue's last edit.
   Skip issues labelled `blocked` or `draft`.
2. Run steps 0 and 1.
3. Post each plan as an issue comment that starts with `## Plan (fan-out)`.
   End it with the open questions and the line "Reply 'go' or start a fan-out
   with this issue to implement."
4. Never implement, open PRs, label or close anything. There is nobody to
   answer questions, so put them in the plan comment.
5. Report the issues planned, the ones skipped (and why), and the ones that
   could not be planned (and what is missing).
