# review-loop

Fresh Opus and Gemini reviewers, round after round, until they approve.

**Say:** "review loop", "council". ship-it also runs it before the PR, unless you skip it.

A second opinion, as many times as it takes: three rounds by default, up to five for security, auth, data loss or concurrency. Two reviewers from different model families, Opus and the newest Gemini Neon through Antigravity at xhigh, read it side by side unless you name others. Each runs in its own T3 thread with no history (a plain subagent outside T3, where only your current provider's reviewer runs) and labels each finding blocker, should or nit. You check each verdict as it arrives and edit once all reviewers have returned. You fix what's real, push back with evidence, and decline scope creep. Say "council" to get three providers at once: Claude Opus, GPT Sol and Gemini Neon through Antigravity. The verdicts per round end up in the PR description.

---

Part of [Good Vibes Only](../../../../README.md). The instructions the agent follows are in [SKILL.md](SKILL.md).
