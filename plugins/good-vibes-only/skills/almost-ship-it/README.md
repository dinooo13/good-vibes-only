# almost-ship-it

Everything ship-it does, except the merge: proof, a review loop, the PR and babysitting, then a PR that's ready for you to merge.

**Say:** "almost ship it", "ship it but don't merge", "get it ready to merge"

For when you want the last word. It proves the change with verify, has review-loop check it, opens the PR and babysits CI and the review bots until the merge gate passes. Then it stops and hands the PR over as ready to merge, waiting for an approval, or blocked, with the reason. It never merges: it turns off auto-merge and keeps the PR out of merge queues while it works. When you're happy, say "ship it" and ship-it merges, deploys and checks it live, without redoing the proof or the review.

---

Part of [Good Vibes Only](../../../../README.md). The instructions Claude follows are in [SKILL.md](SKILL.md).
