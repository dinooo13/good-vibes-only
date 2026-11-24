# review-loop

Fresh Opus and Kimi reviewers, round after round, until they approve.

**Say:** "review loop", "council". ship-it also runs it before the PR, unless you skip it.

A second opinion, as many times as it takes: three rounds by default, up to five for security, auth, data loss or concurrency. Two reviewers from different model families, Opus at xhigh and the newest Kimi Pro through OpenCode, read it side by side unless you name others. Each runs in its own thread with no history (a plain subagent outside T3, where only Opus runs) and labels each finding blocker, should or nit. You start on the first verdict while the second is still reading. You fix what's real, push back with evidence, and decline scope creep. Say "council" to get three providers at once: Claude Opus, GPT Sol and a third through OpenCode. The verdicts per round end up in the PR description.

---

Part of [Good Vibes Only](../../../../README.md). The instructions Claude follows are in [SKILL.md](SKILL.md).
