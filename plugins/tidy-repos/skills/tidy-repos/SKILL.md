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
  then act on the user's go. Skip the confirmation if they already said go,
  for example "delete all but main".
- **Scheduled run:** nobody can answer, so act only on the safe set below and
  report the rest.

## Never

- Touch the default branch, release branches, or branches with an open PR.
- Delete a branch or worktree with uncommitted changes, untracked files that
  matter, or commits that exist nowhere else.
- Remove a worktree that a T3 thread is still using. To check, call
  `t3_thread_list` with `allProjects: true` and the statuses
  `running`, `waiting`, `starting`, `queued` and `preparing`. Leave any
  worktree whose path or branch belongs to one of those threads.
- Use `--force` on anything, or push anywhere except to delete a merged
  branch.
- Delete branches in repos the user does not own.

## Steps per repo

1. Run `git fetch --prune origin` and find the default branch.
2. Find merged branches. Squash and rebase merges do not show up in
   `git branch --merged`, so ask GitHub:
   `gh pr list --state merged --limit 200 --json headRefName,mergedAt,headRefOid`.
   A branch counts as merged when:
   - a merged PR's head is that branch, and
   - the branch tip equals that PR's head commit, or is an ancestor of the
     default branch.

   A branch with commits after its PR merged is not done.
3. **Remote branches:** delete the merged ones that still exist
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
5. **Local branches:** delete the merged ones that no worktree has checked out
   (`git branch -d`, never `-D`).
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
