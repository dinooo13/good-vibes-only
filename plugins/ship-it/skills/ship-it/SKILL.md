---
name: ship-it
description: Take a change all the way to done. Prove it, open or update the PR, babysit CI and review bots, rebase when behind, merge, pull main, install or deploy, check it live, clean up. Use when the user says "ship it", "PR and merge", "babysit the PR", "merge when green", "install the latest main", or "make sure prod deployed clean".
---

# Ship it

You own the change until it is merged and running where it belongs. Start at
the step that fits the request: "install the latest main" with nothing to PR
starts at step 5, and "babysit the PR" starts at step 3.

"Ship it", "merge", "merge when green" and "babysit and merge" allow a merge.
"PR" and "babysit the PR" alone stop at the merge gate.

## Project rules

Read the `## Ship` section in `CLAUDE.md` or `AGENTS.md`. It says how to
verify, how to merge, what runs after the merge, and how to check production.
Follow it, including rules like "never kill the copy the user is running". If
the section is missing, infer the steps from the scripts, CI and recent PRs.
At the end, propose a section with the lines `Verify`, `Merge`,
`After merge` and `Live check`. Don't commit it unasked.

## Steps

1. **Prove it.** Branch off the default branch if you're on it. Run what CI
   runs. For UI, look at it running: the T3 preview browser for the web, the
   T3 device tools for simulators, the built app for macOS. Mocked tests
   don't prove the user experience. If you can't prove it, say so.
2. **File the PR.** Update the PR if the branch already has one. Before
   filing:
   - Rebase onto `origin/<default>`.
   - Follow the repo's title style.
   - Write the description problem first, in the user's words, then the fix in
     two or three sentences, how you proved it, `Closes #N`, and the
     model/harness line.
   - Check the PR for secrets.

   Open a real PR, not a draft. Register it with `link_pull_request`.
3. **Babysit.** Handle the existing checks and comments. If the gate in step
   4 already passes, go straight to step 4. Otherwise call
   `watch_pull_request` and end your turn. Don't use sleep loops or
   `gh pr checks --watch`. Children never watch; the owning thread does. On
   each wake, act only on things newer than your latest push:
   - Check every bot finding against the code, and fix the real ones.
   - Answer false positives with a written reason. Resolving a thread needs
     `gh api graphql` with `resolveReviewThread`.
   - Rerun a flaky infrastructure failure once
     (`gh run rerun <id> --failed`).
   - Decline scope creep with a reason, and list it as a follow-up.

   If the user asked for a fresh review, run `review-loop` first.
4. **Merge gate.** On the latest head, all of these must hold:
   - your proof covers the diff
   - required checks are green
   - the bots the repo waits on, if it runs any (such as Greptile or
     Macroscope), have reviewed it. CodeRabbit never gates.
   - every finding is fixed or answered
   - no human review requests changes
   - GitHub reports the PR as up to date, not `BEHIND` or `DIRTY`

   If it's behind, rebase, push with `--force-with-lease` (only this PR's
   branch) and wait for green again. Never use `--admin`. Without permission
   to merge, report it ready and call `unwatch_pull_request`. Otherwise run
   `git fetch`, check the PR once more, and merge with the repo's method:
   `gh pr merge --<method> --match-head-commit <gated sha>`. Many of the
   user's repos are rebase only. Merge stacked PRs in order, rebasing the next
   one onto the new base after each merge.
5. **After the merge.**
   - Pull main in the root checkout (`git -C <root> pull --ff-only`), if it's
     on the default branch and clean.
   - Run the `After merge` step from that fresh main: install, deploy or
     both. Replace only the installed copy of an app, never with `killall`.
   - For a deploy pipeline, find the run for the merge commit with
     `gh run list --commit <sha>`. If it isn't there yet, retry once with a
     background `sleep 30; gh run list --commit <sha>` and
     `t3_background_wait`. Wait for the run with one background
     `gh run watch <id> --exit-status`, then `t3_background_wait`.
   - Check the change live, in the preview browser or with curl. Look at the
     changed thing, not just at a 200.
6. **Clean up.**
   - Delete the remote branch unless the repo does that itself. First check
     that `origin/<branch>` still equals the PR head, so nothing pushed after
     the merge is lost.
   - Delete the local branch only if no worktree has it checked out. Your own
     T3 worktree usually does, so leave it for `tidy-repos`. After a squash or
     rebase merge, `-D` is fine once GitHub shows the PR merged and the local
     tip equals its head.
   - T3 settles the thread when its PR merges. If the user asked for it and the
     thread is still open, call `t3_thread_organize` with `settle`.

## Report and asking

Report:
- the PR and the merge commit
- your proof
- what was installed or deployed, and what the live check showed
- the decisions you made
- the follow-ups you declined

Ask only when you are blocked: you can't prove the change, the gate can't
pass, the step touches data or production beyond the deploy, or the goal is
ambiguous. Ask with `AskUserQuestion`, putting the context and your
recommendation in the question. Call `unwatch_pull_request` first.
