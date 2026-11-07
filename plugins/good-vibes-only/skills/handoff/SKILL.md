---
name: handoff
description: Write a self-contained brief so a new session, a new T3 thread or a /goal run can continue the work without this thread's history. Use when the user says "write a handoff", "hand this over", "start a new thread for this", "continue in another session", or "do the next round in a new session", and before launching a T3 thread or a long-running implementer that must work alone.
---

# Handoff

The reader has none of this conversation. It needs:
- the task and why it matters
- what's already decided
- what's off limits
- how to prove it's done

## Where it goes

Use the mode the user asks for. Default to launch when they want a new thread,
otherwise to chat.

- **chat:** print the brief.
- **file:** write `.claude/handoff-<slug>.md`, uncommitted.
- **launch:** pass it as `message` to `t3_thread_launch`.
- **goal:** a `/goal …` prompt under 4,000 characters. Put the stop condition
  first and move the details into a file like `PLAN.md`.

## Shape

```markdown
<The task in one sentence.> <Where it ends: report | PR opened, not merged | merged and installed.>

## Why
## Decided (do not reopen)
## Read first (binding docs and issues)
## Starting point (repo path, branch, base SHA, what's done and verified)
## Scope (in / out)
## Verify
## Coordinate (other threads and ids, locks, "start after PR #N merges", who to message)
## Done when
## Report
```

Use absolute paths, SHAs and PR links. Give each decision with its reason,
close to the user's words. Say what is verified and what is not. Never include
secrets; tell the next thread to use `request_secret`. Stay under about 1,500
words.

## Launching in T3

- **Commit first.** A new worktree starts from `baseRef` without your
  uncommitted edits. Push too, unless you use `startFromOrigin: false`. Put
  that SHA under "Starting point".
- **Code changes** get
  `workspaceStrategy: {type: "worktree", baseRef, branch}`. To stack on a
  branch, use it as `baseRef` with `startFromOrigin: false`.
- **Read-only work** uses `{type: "root"}`, with "read only" written into the
  message.
- Pass `projectId`, plus `environmentId` for another machine
  (`t3_environment_links` lists them).
- Pass `modelSelection` only if the user named a model.
- Set `delegatedFrom` to `{environmentId, threadId, title}` of this thread.

Give the user the thread's `link`, and don't poll it. If this thread must hear
back, put your thread id under "Coordinate" and ask for a `t3_thread_send`. If
the user wants this thread settled, settle it yourself with
`t3_thread_organize`; it applies at the end of your turn.
