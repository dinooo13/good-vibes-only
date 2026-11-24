---
name: almost-ship-it
description: Do everything ship-it does up to the merge, then stop with the PR ready for the user to merge. Prove it, review it with review-loop, open or update the PR, babysit CI and review bots, rebase when behind, and hand it over at the merge gate. Never merge. Use when the user says "almost ship it", "ship it but don't merge", "get it ready to merge", "PR it", or "ready for review".
---

# Almost ship it

Do the same work as `ship-it`, but stop with the PR ready for the user to
merge. Never merge it.

Read [ship-it](../ship-it/SKILL.md) and follow its project rules and steps 1
to 4: prove, review, file the PR, babysit, and the merge gate. The rules below
take precedence.

## No merging

You may commit, push, rebase, and push this PR's branch with
`--force-with-lease`. Never merge, turn on auto-merge, add the PR to a merge
queue, push to the default branch, or ask another agent to do any of these.

Before you start, turn off auto-merge (`gh pr merge <n> --disable-auto`) and
take the PR out of a merge queue if it's in one. Check again before each push,
and report it if you changed either.

## Stop at the gate

Use ship-it's merge gate as the readiness check on the final head. The proof
and the review must cover the final diff: after a fix that changes behaviour,
or a conflict fix that does, prove it again and run another review round.

Before handing over, fetch and check the live PR once more: open, not a
draft, its head is the SHA you gated, and GitHub reports it mergeable. Then
call `unwatch_pull_request` and hand over in one of these states:

- **Ready to merge:** the gate passes.
- **Waiting for approval:** only a required human approval is missing.
- **Blocked:** say what blocks it and what you recommend.
- **Merged by someone else:** say so.

Skip ship-it's steps 5 and 6. Nothing is installed or deployed, and the
branch stays.

## Report

- the PR, its head SHA and the state
- your proof
- the review rounds and verdicts
- the decisions you made and the follow-ups you declined

End with one line: say "ship it" to merge. ship-it then starts at its merge
gate and keeps your proof and review while the head is unchanged.
