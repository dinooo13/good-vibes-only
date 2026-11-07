---
name: ship-it
description: Take a finished change all the way to done. Verify it, open or update the PR, babysit review and CI, rebase when the branch falls behind, merge, pull main, run the project's install or deploy, check the result live, then clean up branches. Use when the user says "ship it", "PR and merge", "babysit the PR", "merge when green", "install the latest main", "make sure prod deployed clean", or otherwise asks to land a change.
---

# Ship it

The user says "ship it" so they don't have to prompt every step. You own the
change from the working tree until it is merged and running where it belongs:
installed on this machine, deployed to production, or both.

Work in T3 Code with T3's tools. The steps name them. Outside T3, use the
harness's equivalent and say which one you used.

## 0. Read the project's ship rules

Look in `CLAUDE.md` and `AGENTS.md` for a `## Ship` section. It says how to
verify a change, how the repo merges, what to run after the merge, and how to
check production. Follow it exactly, including rules such as "never kill the
copy of the app the user is running".

If there is no such section, work it out from the README, scripts, CI
workflows and recently merged PRs. At the end, show the user a proposed
section in this shape. Do not commit it unasked.

```markdown
## Ship
- Verify: <how to see the change working: preview URL, simulator, command>
- Merge: <rebase | squash | merge> (<required checks>)
- After merge: <install or deploy command, and where it runs>
- Live check: <URL or command that proves the result is good>
```

## 1. Prove the change before the PR

- If you are on the default branch, create a branch first.
- Run the checks CI runs: build, lint, typecheck, tests.
- Get proof that you observed yourself. For UI, look at it running:
  - web: the T3 preview browser (`preview_open`, `preview_snapshot`,
    `preview_resize` for mobile widths)
  - iOS or Android simulator: the T3 device tools (`device_list`, then
    `device_open`, then `device_screenshot`)
  - macOS apps: run the build and use computer use or screenshots.

  Green mocked tests do not prove the user experience.
- If you cannot prove a change, say so before going further.

## 2. File or update the PR

- Check whether the branch already has a PR. If it does, update that one.
- Rebase onto the latest default branch: `git fetch origin`, then
  `git rebase origin/<default>`.
- Follow the repo's title conventions; look at recent merged PRs. The title
  says why the change matters.
- Open the description with the problem, in the user's terms. Then give the
  solution in two or three sentences. Then one line on how you proved it.
  Then `Closes #N` for the issue. End with the model and harness line. Do not
  lead with an inventory of files.
- Check the title, the description and any attachments for secrets and
  private details.
- Open a real PR, not a draft, so review bots run.
- In T3, register it with `link_pull_request`.

## 3. Babysit review and CI

- Handle the checks and comments that already exist. Then call
  `watch_pull_request` and end your turn. T3 wakes you on failed checks,
  green required checks, new comments or reviews, and conflicts.
  - No `sleep` loops, no `gh pr checks --watch`, no Monitor for PR waits.
    Use one watcher per PR.
  - A delegated child never watches. The thread that owns the PR does.
- On each wake, act only on things newer than your latest push.
  - Check every bot finding against the source. Fix real findings and get
    proof for each fix before you push.
  - Dismiss false positives with a short written reason, then resolve the
    thread.
  - CodeRabbit is advisory. Never wait for it or hold a merge for it.
  - A flaky infrastructure failure gets one rerun (`gh run rerun <id> --failed`).
    Fix real failures.
- Keep the PR at the size the goal needs. Decline cheap-looking extras (edge
  case guards, extra tests, extra compatibility) with a reason and list them
  as follow-ups.
- If the user asked for a fresh review or a council, run the `review-loop`
  skill before merging.
- When a wake needs no action, end the turn without a message.

## 4. Merge gate

All of these must be true on the latest head:

- Your proof covers every change in the diff.
- Required checks are green.
- Review bots have finished, and every finding is fixed or dismissed with a
  reason.
- No human review still requests changes.
- The branch is up to date with the base. GitHub reports it as mergeable, not
  `BEHIND` or `DIRTY`. No base commit that landed after the last green run
  touches the PR's files.

If the branch is behind, rebase it, push with `--force-with-lease` (only for
this PR's own branch), and wait for green again. Never use `--admin` or any
other bypass of branch protection.

"Ship it" is permission to merge. If the user said they will review or merge
themselves, stop here. Report that the PR is ready and call
`unwatch_pull_request`.

Right before merging, run `git fetch` and check the PR again. Merge with the
method the repo allows; many of the user's repos are rebase only. For stacked
PRs, merge in order and rebase the next one onto the new base after each
merge.

## 5. After the merge

1. **Update local main** in the project's root checkout, not in your
   worktree. Do this only if the root checkout is on the default branch and
   clean: `git -C <root> pull --ff-only`. Otherwise report why you skipped it.
2. **Run the `After merge` step** from `## Ship`. Install or deploy from the
   newly pulled main, never from the PR branch.
   - **Apps the user is running:** stop and replace only the installed copy,
     the way the project says. Never use `killall`. Start the new build when
     the user asked for that.
   - **Physical devices:** use the project's install command, then check that
     the app launches.
   - **Deploy pipelines:** find the deploy run (`gh run list --branch <default>`)
     and wait for it with one background command:
     `gh run watch <id> --exit-status`, with `run_in_background`, followed by
     `t3_background_wait`.
3. **Check it live.** Open the production URL in the T3 preview browser, or
   curl it. Look at the thing that changed, not only at a 200 status. Close
   preview tabs you opened.

## 6. Clean up

- Delete the merged branch on the remote (if the repo does not do that
  automatically) and locally.
- Do not remove the worktree this thread runs in. The `tidy-repos` skill
  removes merged worktrees later. You may remove other worktrees this thread
  created, if they are clean and their branch has merged.
- Never delete branches or worktrees you did not create unless the user asks.
- T3 settles a thread when its linked PR merges. If the thread is still
  active once the work is done and the user asked for it to be settled, call
  `t3_thread_organize` with `{"action":"settle"}`.

## 7. Report

Keep it short:
- the PR link and the merge commit
- your proof
- what was installed or deployed, and the live check result
- each decision you made for the user
- the follow-ups you declined

## When to ask

Ask only when you cannot continue on your own:
- you cannot prove the change
- the merge gate cannot pass and you cannot fix it
- the next step deletes data, touches production data, or changes something
  outside the repo
- the goal is ambiguous in a way that changes the result
- another PR makes this one obsolete

Use `AskUserQuestion` with all the context in the question: the PR link, what
blocks you, and the options with your recommendation first. Call
`unwatch_pull_request` before you stop to ask.
