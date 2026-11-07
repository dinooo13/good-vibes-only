---
name: review-loop
description: Review a change with a fresh Opus xhigh reviewer in its own thread, fix what it finds, and repeat until it approves. With "council", three providers review in parallel. Use when the user says "review loop", "review rounds", "council", "get a fresh review", or "review until it's clean", or asks another model to review a change before it merges.
---

# Review loop

A fresh reviewer reads the change, you fix what's real, and a new reviewer
checks again until it approves. Make the smallest changes that satisfy it. Push
back with evidence, and fight scope creep.

## Reviewers

Call `orchestrator_capabilities` and take the newest model of each family.
Never hardcode IDs. A reviewer the user names wins.

- **Default:** the newest Claude Opus at `xhigh`.
- **Council:** one flagship per provider at high effort or above: the newest
  Claude Opus, GPT Sol, and a third provider through OpenCode (Kimi Pro,
  else GLM). If one can't run, say so instead of substituting.

Start each reviewer with `delegate_task` (`role: "review"`, `mode: "async"`,
a new `clientRequestId`). Every round is a new `delegate_task`, never
`t3_thread_send`. Don't edit the files under review while it runs, and don't
poll. A timeout or an error is not an approval.

## Budget

Run 3 rounds. Allow up to 5 for security, auth, data loss or concurrency while
a blocker or should finding is open. Stop early when a round returns only
nits.

## Round 1

Before starting, fix known issues and outstanding PR comments, then run the
covering checks. Find the base with `git merge-base HEAD origin/<base>`.
Don't include unrelated changes.

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
SCORE: <n>/10
VERDICT: APPROVE or CHANGES
R1 [blocker|should|nit] <file>:<line> <claim>. Fix: <suggestion>
```

## Answering findings

Check each finding and its severity yourself.

- **You agree:** make the smallest fix, deleting or narrowing code where you
  can.
- **You disagree:** reply with evidence: file and line, a test, or output.
- **It's a nit or out of scope:** decline it in one line and list it as a
  follow-up.

Keep a ledger with the id, severity and outcome of each finding. Re-run the
checks, and if the diff grew, cut it back first. Record the SHA each round
reviewed: commit first, or use `git stash create`.

The next round gets a fresh reviewer, with the brief, the ledger and
`git diff <last reviewed sha>`. It checks only the open ids and the changed
code.

## Stopping

- **Done:** every reviewer approves the current diff, or the last round
  returned only nits, and no blocker or should is open.
- **Stuck:** a finding is still disputed after two replies, or the budget ran
  out. Show both sides in a few lines and let the user decide.

If there is a PR, add the scores to its description, before the model line.
Edit the description; don't post a comment. Without a PR, put them in the
report.

```markdown
## Review loop

| Reviewer | Round 1 | Round 2 |
| --- | --- | --- |
| Claude Opus 5.5 (xhigh) | 7/10 | 9/10 |
```

If a reviewer gave no score, write `no score`. Push only if the user asked you
to push or ship. Report:
- the rounds and the score per round
- the fixed and declined findings, with reasons
- the diff size before and after
