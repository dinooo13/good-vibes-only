---
name: tidy-repos
description: Clean up git leftovers across local repositories. It deletes branches whose PRs merged (local and remote), removes clean worktrees whose branch merged, and lists stale unmerged work for the user to decide on. Use when the user says "clean up branches", "delete merged branches", "delete dangling branches", "clean up worktrees", or "tidy my repos", and when a scheduled task runs it.
---

# Tidy repos

Delete only what is provably done. Everything else gets reported, never
touched.

**Scope:** the repo the user names. Otherwise every project returned by
`t3_project_list` (in T3), plus any repo directly under `~/Developer` if it
exists, and `~/.t3/worktrees`.

**Interactive runs** show the plan first, unless the user already said go.
**Scheduled runs** act on the safe set and report the rest. Either way,
unmerged branches are only ever listed.

## Merged means

A merged PR's head is the branch, and the tip equals the PR's `headRefOid` or
is an ancestor of the default branch. Check each candidate non-default branch
(local or remote) with `gh pr list --state merged --head <branch> --json headRefOid`
(or `pull_request_list` when available). Squash and rebase merges don't show up
in `git branch --merged`. Check the local tip and `origin/<branch>` separately:
one with later commits is not done.

## Per repo

1. Run `git fetch --prune origin`.
2. Delete merged remote branches that still exist:
   `git push origin --delete <branch>`.
3. Remove a worktree with `git worktree remove <path>`, without `--force`,
   only when all of these hold:
   - its branch is merged
   - `git status --porcelain` is empty
   - it has no commits beyond the merged PR's `headRefOid`
   - `git status --porcelain --ignored` shows only build or dependency output
     (`node_modules`, `dist`, `.build` and the like). Report worktrees that
     hold ignored `.env` files, databases or `hill-climb/` media.
   - it belongs to no unsettled T3 thread. To check, call `t3_thread_list`
     with `allProjects: true`, `settled: false` and `includeSubagents: true`,
     paging with `cursor` until the list ends. Then read each thread's
     `worktreePath` with `t3_thread_read` (`limit: 1`). Idle threads count too.

   Then run `git worktree prune`.
4. Delete merged local branches that no worktree has checked out, with
   `git branch -d`. If a squash or rebase merge makes it refuse, `-D` is
   allowed only when the tip matches the rule above.
5. List stale work: unmerged branches and worktrees with no commit in 30
   days. Give the last commit date, the PR state, any uncommitted changes, and
   a suggested action.

**Never:**
- touch the default or release branches, or branches with an open PR
- delete anything with uncommitted or unique commits
- use `--force`
- delete in repos the user doesn't own

**Report** the counts per repo, the disk space freed (`du -sh` before and
after), the stale list, and what was skipped and why.
