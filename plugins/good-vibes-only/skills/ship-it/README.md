# ship-it

Proof, a review loop, PR, babysitting, rebase, merge, pull main, install or deploy, a live check, cleanup.

**Say:** "ship it", "merge when green". Add "skip the review" for a change that doesn't need one.

"Ship it" should mean shipped. The skill proves the change with verify and has review-loop check it before the PR, then babysits checks and review bots: it fixes the real findings, answers false positives with a reason, and declines scope creep. It rebases when the branch falls behind and only merges once the gate is green. After the merge it pulls main, installs or deploys, and looks at the result live. Each project describes its verify, merge, after-merge and live-check steps in a `## Ship` section of its `CLAUDE.md` or `AGENTS.md`. Without one, the skill works them out from the repo and proposes the section; build-verification-environment writes it for you.

"PR" or "babysit the PR" alone stops at the merge gate.

---

Part of [Good Vibes Only](../../../../README.md). The instructions the agent follows are in [SKILL.md](SKILL.md).
