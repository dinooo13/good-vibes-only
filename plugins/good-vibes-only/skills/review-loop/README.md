# review-loop

Fresh Opus xhigh reviewers, round after round, until one approves.

**Say:** "review loop", "council". ship-it also runs it on every change before the PR.

A second opinion, as many times as it takes: three rounds by default, up to five for security, auth, data loss or concurrency. The reviewer, Opus at xhigh unless you name another, runs in its own thread with no history (a plain subagent outside T3) and labels each finding blocker, should or nit. You fix what's real, push back with evidence, and decline scope creep. Say "council" to get three providers at once: Claude Opus, GPT Sol and a third through OpenCode. The verdicts per round end up in the PR description.

---

Part of [Good Vibes Only](../../../../README.md). The instructions Claude follows are in [SKILL.md](SKILL.md).
