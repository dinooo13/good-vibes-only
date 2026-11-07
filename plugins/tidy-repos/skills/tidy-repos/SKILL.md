---
name: tidy-repos
description: Clean up git leftovers across local repositories. It deletes branches whose PRs merged (local and remote), removes clean worktrees whose branch merged, prunes stale refs, and lists stale unmerged work for the user to decide on. Use when the user says "clean up branches", "delete merged branches", "delete dangling branches", "clean up worktrees", "tidy my repos", or when a scheduled task runs it.
---

# Tidy repos

Delete only what is provably done. Merged and clean goes; everything else is
reported, never touched.

## Scope

- The repo the user names. Otherwise every git repository directly under
  `~/Developer`, and every worktree under `~/.t3/worktrees`.
- **Interactive run:** first show the plan (what will be deleted, per repo),
  then act on the user's go. Skip the confirmation if they already said go
  ("yes, go ahead"). Even then, unmerged branches are only listed, never
  deleted.
- **Scheduled run:** nobody can answer, so act only on the safe set below and
  report the rest.

## Never

- Touch the default branch, release branches, or branches with an open PR.
- Delete a branch or worktree with uncommitted changes, untracked files that
  matter, or commits that exist nowhere else.
- Remove a worktree that a T3 thread may still use. Call `t3_thread_list`
  with `allProjects: true` and `settled: false`. For each thread it returns,
  `t3_worktree_list` with that `threadId` gives its checkout path and branch.
  Leave every worktree that belongs to an unsettled thread, including idle
  ones: the user may come back to them.
- Use `--force`, or `git branch -D` outside the rule in step 5. Push only to
  delete a merged branch.
- Delete branches in repos the user does not own.

## Steps per repo

1. Run `git fetch --prune origin` and find the default branch.
2. Find merged branches. Squash and rebase merges do not show up in
   `git branch --merged`, so ask GitHub:
   `gh pr list --state merged --limit 200 --json headRefName,mergedAt,headRefOid`.
   A branch counts as merged when:
   - a merged PR's head is that branch, and
   - the branch tip equals that PR's `headRefOid`, or is an ancestor of the
     default branch.

   Check the local branch and `origin/<branch>` separately. A copy with
   commits beyond the PR's head (pushed later, perhaps from another machine)
   is not done.
3. **Remote branches:** delete the merged ones that still exist, after
   checking `origin/<branch>` against the rule above
   (`git push origin --delete <branch>`). Skip branches the repo deletes
   automatically.
4. **Worktrees** (`git worktree list --porcelain`): remove one with
   `git worktree remove <path>`, without `--force`, only when all of these
   hold:
   - its branch is merged
   - `git -C <path> status --porcelain` is empty
   - it has no unpushed commits
   - no active T3 thread uses it

   Then run `git worktree prune`.
5. **Local branches:** delete the merged ones that no worktree has checked
   out, with `git branch -d`. After a squash or rebase merge, `-d` refuses.
   Then `git branch -D` is allowed, but only when the local tip equals the
   merged PR's `headRefOid` or is an ancestor of the default branch. Never use
   `-D` in any other case.
6. **Report stale work, don't delete it:** unmerged branches and worktrees with
   no commit in the last 30 days. Give the last commit date, whether there is
   an open or closed PR, and whether there are uncommitted changes.

## Report

- Per repo, how many remote branches, local branches and worktrees were
  removed.
- The disk space freed by removed worktrees: `du -sh` before and after.
- The stale list, each with a suggested action, such as "closed PR, unmerged:
  delete?" or "uncommitted changes from 12 Oct: look at it".
- Anything skipped, and why.
