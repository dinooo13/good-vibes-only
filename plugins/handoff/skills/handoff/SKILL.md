---
name: handoff
description: Write a self-contained brief so a new session, a new T3 thread, a delegated child or a /goal run can continue the work without this thread's history. Use when the user says "write a handoff", "hand this over", "start a new thread for this", "continue in another session", "do the next round in the same manner", and before launching any thread or child that must work alone.
---

# Handoff

The reader has none of this conversation. It needs:
- what to do, and why
- what is already decided
- what it must not touch
- how to prove that it is done

Everything else is noise.

## Output modes

Pick the mode from the user's words. Default to **launch** when they asked
for a new thread, otherwise to **chat**.

| Mode | What you do |
| --- | --- |
| chat | Print the brief in the reply. No file. |
| file | Write `.claude/handoff-<slug>.md`. Do not commit it unless asked. |
| launch | Start a T3 thread with `t3_thread_launch`, with the brief as `message`. |
| goal | Write a `/goal …` prompt of at most 4,000 characters, for a thread that keeps going until the condition holds. |

## The brief

```markdown
<One sentence: the task.> <Where it ends: report only | PR opened, not merged | merged and installed.>

## First action
<Only when the user wants the parent settled:> Settle the thread that launched you:
call `t3_thread_organize` with {"action":"settle","threadId":"<parent thread id>"}. Then do the task.

## Why
<The user's goal and motivation, in a few lines, close to their own words.>

## Decided (do not reopen)
- <Each decision the user made, and the options they rejected.>

## Read first (binding)
- <CLAUDE.md, AGENTS.md, the docs and issues it must follow, with paths or `gh issue view N`.>

## Starting point
- Repo: <absolute path>   Branch: <name>   Base: <sha or branch>
- State: <what's done, with commit SHAs and PR links; what's verified and what isn't>

## Scope
- In: <…>
- Out: <…>

## Verify
- <Checks to run, how to see it working (preview browser, simulator, device), and the measurements it needs.>

## Coordinate
- <Other threads working at the same time, with ids; shared resources and the lock protocol; "start only after PR #N merges".>

## Done when
- <A testable list.>

## Report
- <What the final message must contain: PR link, proof, decisions made, open questions.>
```

## Rules

- Use absolute paths, branch names, commit SHAs and PR links. No "the file we
  discussed".
- Paraphrase the user's decisions closely. A decision without its reason gets
  reopened.
- Say what is verified and what is not. Do not hand on a guess as a fact.
- Never put secrets in a brief. If the next thread needs one, tell it to call
  `request_secret`.
- Keep it under about 1,500 words. Link to docs instead of copying them in.
- For goal mode, put the stop condition first and keep the whole prompt under
  4,000 characters. Move details into a file in the repo, such as `PLAN.md`,
  and point to it.

## Launching in T3

- Code changes get a worktree:
  `workspaceStrategy: {type: "worktree", baseRef: "<base>", branch: "<name>"}`.
  To stack on a parent branch, use that branch as `baseRef` with
  `startFromOrigin: false`.
- Read-only work runs in the root checkout: `{type: "root"}`.
- Pass `projectId` for the right project. To work on another machine, pass
  its `environmentId`; `t3_environment_links` lists the machines.
- Inherit the model unless the user named one. Pass it in `modelSelection`
  with the options from `orchestrator_capabilities`.
- Set `delegatedFrom` to this thread, so the new thread shows where it came
  from.
- After the launch, give the user the thread's `link`. Do not poll it. If the
  user wants this thread settled once the new one is running, settle it with
  `t3_thread_organize`.
