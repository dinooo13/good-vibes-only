---
name: review-loop
description: Review a change with fresh reviewers from different model families, fix what they find, and repeat until they approve. With "council", three providers review in parallel. Use when the user says "review loop", "review rounds", "council", "get a fresh review", or "review until it's clean", or asks another model to review a change before it merges.
---

# Review loop

A fresh reviewer reads the change, you fix what's real, and a new reviewer
checks again until it approves. Make the smallest changes that satisfy it. Push
back with evidence, and fight scope creep.

## Reviewers

Call `orchestrator_capabilities` and take the newest model of each family.
Never hardcode IDs. A reviewer the user names wins.

- **Default:** two reviewers in parallel: the newest Claude Opus at `xhigh`
  and the newest Gemini Neon through Antigravity at `xhigh` `thought_level`.
- **Council:** one flagship per provider at high effort or above: the newest
  Claude Opus, GPT Sol, and Gemini Neon through Antigravity. If one can't
  run, say so instead of substituting.

In T3 Code, always start every reviewer with `delegate_task` (`role: "review"`,
`mode: "async"`, a new `clientRequestId`) — never a native subagent tool
(`Agent`, `spawn_agent`, `invoke_subagent`) and never `t3_thread_send`. Every
round is a new `delegate_task`. Don't edit the files under review while it runs,
and don't poll. A timeout or an error is not an approval; retry a failed
reviewer once, then report that it didn't run and ask the user if you can't
reach sign-off. With several reviewers, check each result as it arrives and edit
once all have returned.

Only outside T3 (when `delegate_task` isn't available), fall back to your
harness's native subagent tool with the same brief. Only your current provider's
reviewer can run there; say which others couldn't.

## Budget

Run 3 rounds. Allow up to 5 for security, auth, data loss or concurrency while
a blocker or should finding is open. Stop early when a round returns only
nits.

## Round 1

Before starting, fix known issues and outstanding PR comments, then run the
covering checks. Find the base with `git merge-base HEAD origin/<base>`.
Don't include unrelated changes. Give each reviewer a short ID prefix (such as
`O` for Opus, `G` for Gemini, `S` for Sol) so parallel ledgers never collide.

Brief:

```text
Review only. Do not edit, commit, push, comment on GitHub, or start subagents.
Repo: <abs path>  Base: <sha>  PR: <url or none>
Intent: <1-2 sentences>  Out of scope: <…>  Checks: <results>
See: git diff <base>; git status --short (read untracked files).
Find bugs, broken callers, and mismatches with the intent. Skip style unless it
hides a bug. Flag code, tests or guards the intent does not need.
blocker = intended case wrong. should = real bug callers will hit. nit = the rest.
Reply:
VERDICT: APPROVE or CHANGES
<prefix>1 [blocker|should|nit] <file>:<line> <claim>. Fix: <suggestion>
```

## Answering findings

Check each finding and its severity yourself.

- **You agree:** make the smallest fix, deleting or narrowing code where you
  can.
- **You disagree:** reply with evidence: file and line, a test, or output.
- **It's a nit or out of scope:** decline it in one line and list it as a
  follow-up.

Keep a ledger with the id, severity and outcome of each finding. Re-run the
checks, and if the diff grew, cut it back first. Commit your fixes before the
next round (you can tidy or squash commits before opening the PR) and record
the SHA each round reviewed.

The next round starts fresh reviewers for every seat, with the brief, the
ledger, `git diff <base>` for context, and `git diff <last reviewed sha>` for
what changed. They check only the open ids and regressions in what changed.

## Stopping

- **Done:** every reviewer approves the current diff, or the last round
  returned only nits, and no blocker or should is open.
- **Stuck:** a finding is still disputed after two replies, or the budget ran
  out. Show both sides in a few lines and let the user decide.

If there is a PR, add the verdicts to its description (`pull_request_update`,
or `gh` outside T3), before any attribution footer. Edit the description; don't
post a comment. Without a PR, put them in the report.

```markdown
## Review loop

| Reviewer | Round 1 | Round 2 |
| --- | --- | --- |
| Claude Opus 5.5 (xhigh) | CHANGES | APPROVE |
| Gemini 4 Neon (xhigh) | CHANGES | APPROVE |
```

Push only if the user asked you
to push or ship. Report:
- the rounds and each reviewer's verdict
- the fixed and declined findings, with reasons
- the diff size before and after
