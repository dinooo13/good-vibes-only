---
name: almost-ship-it
description: Do everything ship-it does up to the merge, then stop with the PR ready for the user to merge. Prove it, review it with review-loop, open or update the PR, babysit CI and review bots, rebase when behind, and hand it over at the merge gate. Never merge. Use when the user says "almost ship it", "ship it but don't merge", "get it ready to merge", "get it ready for review", or "PR it".
---

# Almost ship it

Do the same work as `ship-it`, but stop with the PR ready for the user to
merge. Never merge it.

Read [ship-it](../ship-it/SKILL.md) and follow its project rules and steps 1
to 4: prove, review, file the PR, babysit, and the merge gate. "Almost ship
it" grants the same testing permission as "ship it". The rules below take
precedence.

## No merging

You may commit, push, rebase, and push this PR's branch with
`--force-with-lease`. Never merge, turn on auto-merge, add the PR to a merge
queue, push to the default branch, or ask another agent to do any of these.

Once the branch has a PR, read `gh pr view <n> --json autoMergeRequest` and
turn auto-merge off (`gh pr merge <n> --disable-auto`) only if it's set. If
the PR is in a merge queue, take it out with `gh api graphql` and the
`dequeuePullRequest` mutation. Check again before each push, and report what
you changed.

## Stop at the gate

Use ship-it's merge gate as the readiness check on the final head. Prove
behaviour changes again, and run a new review round when ship-it's gate
would.

Before handing over, fetch and read the live PR once more with
`gh pr view <n> --json state,isDraft,headRefOid,mergeStateStatus,reviewDecision`:
open, not a draft, and its head is the SHA you gated. Then call
`unwatch_pull_request` and hand over in one of these states:

- **Ready to merge:** the gate passes and `mergeStateStatus` is `CLEAN`.
- **Waiting for approval:** the rest of the gate passes, and the PR is
  `BLOCKED` only because `reviewDecision` is `REVIEW_REQUIRED`.
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
gate, and your proof and review stay valid under its gate rules.
