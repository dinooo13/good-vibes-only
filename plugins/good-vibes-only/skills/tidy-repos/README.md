# tidy-repos

Merged branches and clean worktrees go; stale work gets listed.

**Say:** "clean up branches"

Branches whose PRs merged, worktrees that are clean and merged, stale refs: gone. Squash and rebase merges are detected through GitHub, so nothing is guessed from `git branch --merged`. Anything unmerged or with changes is listed for you, never deleted. It also never touches a worktree that an unsettled T3 thread still owns, or one holding ignored files like `.env`.

---

Part of [Good Vibes Only](../../../../README.md). The instructions the agent follows are in [SKILL.md](SKILL.md).
