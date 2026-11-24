# fan-out

One thread per issue: plan, your go, implement, verify, review, ship.

**Say:** "fan out issues 36, 37 and 38"

Hand it a handful of issues. It writes the missing "Done when" criteria, works out which issues depend on each other, and starts one thread per issue in its own worktree (a T3 thread, or a worktree subagent outside T3). Each thread runs the whole flow: a Fable planner, a short summary for you, an Opus implementer, then verify, review-loop and ship-it on its own PR. You approve all the plans in one place. Threads take turns on shared resources like benchmarks, and a dependent issue starts only after the issue it needs has merged. With `--plan-only` it just posts plans on the issues, which makes a nice overnight job.

---

Part of [Good Vibes Only](../../../../README.md). The instructions Claude follows are in [SKILL.md](SKILL.md).
