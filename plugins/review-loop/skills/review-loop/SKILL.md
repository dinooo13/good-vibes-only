---
name: review-loop
description: Review a change with a fresh Opus xhigh reviewer in its own thread, fix what it finds, and repeat until it approves. With "council", three providers review in parallel. Use when the user says "review loop", "review rounds", "council", "get a fresh review", "review until it's clean", or asks another model to review a change or PR before it merges.
---

# Review loop

A different model reads the change with fresh eyes. You fix what it finds,
and a new reviewer checks again, until it approves. Your job is a correct
change at the size the goal needs, not a change that grows with every round.

## Modes

- **Single (the default):** one reviewer, the newest Claude Opus at `xhigh`.
- **Council:** one flagship model from each of three providers. Use it when
  the user says "council", or for changes going to someone else's repo.

## Budget

- 3 rounds by default. Round 1 is a full review. Later rounds check only the
  open findings and the code that changed since.
- Up to 5 rounds for security, permissions, auth, data loss or concurrency,
  while a blocker or should finding is still open. Also when the user asks.
- Stop early when a round returns only nits.
- One full pass by every reviewer counts as one round.

## 1. Scope

- Run `git status --short`. Do not stash, discard or include unrelated
  changes.
- Find the base after `git fetch origin`:
  - For a PR: `gh pr view <n> --json baseRefName,headRefOid`, then
    `git merge-base HEAD origin/<baseRefName>`.
  - Otherwise: `git merge-base HEAD origin/<default>`.
- Write the intent and what is out of scope, in one or two sentences.
- Before round 1, fix the issues you already know about and answer the
  outstanding PR comments. Then run the checks that cover the change. Never
  send reviewers code you know is broken.

## 2. Pick reviewers

In T3, call `orchestrator_capabilities` once. Resolve models by family and
take the newest version. Never hardcode model IDs.

**Single mode:** the newest Claude Opus at `xhigh`. A reviewer the user names
always wins.

**Council mode:** one model per provider, at high or stronger reasoning:
- the newest Claude Opus (`claudeAgent`)
- the newest GPT Sol (`codex`)
- one more provider through OpenCode, preferring the newest Kimi Pro, then
  GLM

Members the user names win. If a provider or a named member cannot run,
report it. Do not substitute quietly.

Start each reviewer with `delegate_task`:
- `role: "review"`, `mode: "async"`, `isolation: "shared"`
- the model and its options in `target`
- a new `clientRequestId` every round

Every new round is a new `delegate_task`, never `t3_thread_send`. Do not edit
the files under review while reviewers run. Do not poll; wait for the
notification. A timeout, an error or no reply is not an approval.

Outside T3, use the harness's subagent tool with the chosen model.

## 3. Round 1 brief

Children get no history, so the brief must stand on its own:

```text
Review only. Do not edit, commit, push, comment on GitHub, or start subagents.
Repo: <absolute path>   Base: <sha>   PR: <url or none>
Intent: <intent>
Out of scope: <scope>
Checks run: <commands and results>
See: git diff <base> [-- <paths>]; git status --short (read untracked files too).
Read the surrounding code. Find bugs, broken callers, and mismatches with the intent.
Skip style unless it hides a bug. Hold the change to the smallest one that works:
flag code, tests or guards the intent does not need.
Severity: blocker = the intended case is wrong. should = a real bug callers will hit.
nit = everything else (other paths, rare cases, small perf, extra compatibility).
Reply exactly:
SCORE: <n>/10
VERDICT: APPROVE or CHANGES
R1 [blocker|should|nit] <file>:<line> <claim>. Fix: <suggestion>
(stable ids R1, R2, …)
```

For a council, send the same brief to all three in parallel.

## 4. Answer the findings

Check each finding and its severity yourself. Another path, a rare case or a
small cost is a nit, whatever label it came with.

- **You agree:** make the smallest fix. Prefer deleting or narrowing code over
  adding a lock, cache, helper or option. Add one focused test that fails
  without the fix, when the intent needs one.
- **You disagree:** say why, with evidence (file and line, a test, output).
- **Out of scope or a nit:** decline it in one line and list it as a
  follow-up.

Do larger fixes in one Opus `high` implementation delegate, while no review
is running.

Keep a ledger: id, reviewer, severity, outcome (`fixed`, `disagree`,
`declined`), evidence. Then re-run the checks and `git diff --shortstat <base>`.
If the review grew the diff, cut first. Never agree with a finding just to end
the loop.

## 5. Next round

Start a round only if:
- the budget allows it, and
- a blocker or should is still open, or code that changes behaviour changed
  since the last approval.

Send a fresh reviewer the round 1 brief, the ledger, the same base diff and
the change since the last round. Ask it to check only the open ids and the
changed code, and to mark each old id `resolved` or `still open: <reason>`.

## 6. Stop

- **Satisfied:** every reviewer says APPROVE on the current diff, no blocker
  or should is open, and you have no open concern of your own.
- **Stuck:** a finding is still disputed after two replies, or the budget ran
  out. Show both sides in two or three lines each and let the user decide.
  Running out of budget is not an approval.

## 7. Record it

If the work has a PR, add this section to the PR description, before the
model and harness line. Edit the description; do not post a comment.

```markdown
## Review loop

Rounds: 2

| Reviewer | Round 1 | Round 2 |
| --- | --- | --- |
| Claude Opus 5.5 (xhigh) | 7/10 | 9/10 |
```

If a reviewer gave no score, write `no score`. Never invent one.

Do not push during the loop. Push afterwards only if the user asked you to
push, ship or update the PR. If the next step is landing the change, continue
with the `ship-it` skill.

## Report

- rounds and reviewers
- the score per round
- what the review changed
- diff size before and after
- fixed and declined findings, with reasons
- whether anything was pushed
