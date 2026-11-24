# hill-climb

Critic rounds with a fixed rubric until the score reaches the target.

**Say:** "keep iterating until the reviewer gives at least 9"

Give it a target ("at least 9 out of 10") and it brings in a fresh, independent critic every round. The critic never hears the target. It scores the work with a fixed rubric against fresh captures, including the hard states, and ranks what holds the score down. Implementers fix the top defects and the next critic comes back. The climb stops at the target (after one confirmation round), when the score plateaus, or when the budget runs out. The design decisions get written down, so the next change keeps the direction. For code, use review-loop.

---

Part of [Good Vibes Only](../../../../README.md). The instructions Claude follows are in [SKILL.md](SKILL.md).
