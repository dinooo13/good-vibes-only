---
name: hill-climb
description: Improve something round by round until an independent critic scores it at or above a target out of 10. Works for UI and UX, visual fidelity against references, a game scene, copy, or a site. Each round a fresh critic captures the current state, scores it with a fixed rubric and ranks the defects; implementers fix the top ones; repeat. Use when the user gives a target score ("keep iterating until the reviewer gives at least 9"), says "hill climb", or asks for critic rounds. It pairs well with /goal.
---

# Hill climb

A fresh, independent critic scores the work every round with the same rubric.
You fix what holds the score down and go again, until the score reaches the
target, stops climbing, or the budget runs out.

What the critic sees must be real: renders and captures made fresh from the
current commit. Never use screenshots someone describes, or numbers that are
easy to game.

## 1. Set up

Write these into `hill-climb/` in the repo, or in the scratchpad for a
throwaway project. Show them to the user in one message, unless they already
said go.

Commit the rubric, the capture plan, `scores.md` and the critiques: they
document the run. Keep captures and reference media out of git. Add
`hill-climb/captures/` and `hill-climb/reference/` to `.gitignore`, or keep
them in the scratchpad. That way they never land in a PR.

1. **Goal and target.** For example "the critic's headline score is at least
   9.0". Also the round budget (default 8) and any pause points the user wants
   ("pause after round 3 and report").
2. **References** (`hill-climb/reference/`): what "good" looks like.
   - Check that they show what the user means: gameplay footage, not a
     cinematic trailer; the real app, not marketing renders.
   - If you cannot fetch a source (for example an age-gated video), say so
     and ask for screenshots. Do not carry on without references.
3. **Rubric** (`hill-climb/rubric.md`):
   - 5 to 10 axes scored 0–10, each with anchors for what 5, 7 and 9 look like.
   - One holistic **headline** axis that the target applies to, such as "same
     game as the references" or "feels first-party on macOS". The mean of the
     axes is reported too, but metrics that are easy to pass, such as colour
     statistics, never stand in for the headline.
4. **Capture plan** (`hill-climb/captures.md`): a fixed, scripted set of shots
   and states, made the same way every round: same cameras, viewports, data
   and themes. It must include the hard states that hide problems:
   - everything switched on
   - the longest text
   - the smallest and the largest window or viewport
   - empty, loading and error states
   - light and dark
   - real interaction (moving, typing), not only stills
5. **With /goal:** the condition is "the last two critiques in
   `hill-climb/scores.md`, from two different critics, both have a headline of
   at least <target>". That includes the confirmation round from step 4. Keep
   the goal prompt under 4,000 characters and point to these files.

## 2. Critic round

- Start a **fresh** critic for every round with `delegate_task`:
  - `role: "review"`
  - "Never edit source files, commit or push. Write only under
    `hill-climb/critiques/` and `hill-climb/captures/`" written into the task
    text, since `delegate_task` has no read-only flag
  - a strong model: the newest Claude Fable or Opus at `xhigh` (resolve it
    with `orchestrator_capabilities`), or another provider for variety
  - never reuse a critic
- **Give it:** the rubric, the references, the capture plan, the commit to
  judge, and the round 1 critique as calibration, so scores stay comparable
  across rounds.
- **Do not tell it:** the target score, that you hope for a higher score, or
  the user's frustration. Ask it to be rigorous and to judge independently.
- **It produces its own captures**, following the capture plan: the T3 preview
  browser for the web, the T3 device tools for simulators, a build plus
  screenshots for desktop apps.
- **It writes `hill-climb/critiques/critique-<n>.md`**, with its captures in
  `hill-climb/captures/<n>/`. The critique contains:
  - a table of every axis: last round, now, change
  - the headline score and a one-paragraph verdict
  - each fix claimed since the last round: fixed, partly fixed or not fixed,
    with evidence
  - new regressions
  - the top defects (at most 10), ranked by gain per effort, each with a
    concrete fix and a time estimate
  - where its captures are
- Append the round to `hill-climb/scores.md`:
  round, commit, headline, mean, and a short note.

## 3. Fix round

- **Cluster** the defects by area. Start one implementer per cluster, as
  `delegate_task` children with `isolation: "worktree"` or on disjoint files:
  - Sonnet for clearly specified fixes
  - Opus `high` for fixes that need judgement
- **Hand each implementer** the defect text, the files involved, how to check
  its own result, and "do not commit to main".
- **Integrate**, check that the build passes, and commit a snapshot per round.
  The next critic judges that commit.
- **Run measurements one at a time** when they share hardware: GPU frame
  times, Neural Engine benchmarks, a simulator, a device. Parallel browsers on
  one GPU make fps numbers worthless. Tell every implementer to take a lock
  first: `mkdir /tmp/<repo>-<resource>.lock`. If that fails, wait with one
  background command, `until mkdir … 2>/dev/null; do sleep 30; done`. Release
  the lock with `rm -r`.
- Fix the real defect, not the metric.
- If the headline drops, fix or revert the regression before adding anything
  new.

## 4. Loop control

Stop when one of these holds:

- **Target reached.** Run one confirmation round with another fresh critic;
  both must be at or above the target.
- **Plateau.** Two rounds in a row add less than 0.2 to the headline. Report
  what blocks progress and what would move it, for example better assets or a
  bigger change.
- **Budget** used up, or a pause point the user set.
- **Usage limits** close. Load the `usage-limits` skill if it is installed,
  and leave `scores.md` and the latest critique as the handoff.

The user may change the target mid-run ("you may stop at 9.0"). Follow it.

## 5. Taste mode

When the remaining feedback is about feel (how an animation moves, how lively
a waveform is), critic rounds stop helping. Switch to short loops with the
user:

1. install or run the build for them
2. ask one specific question
3. change one parameter set
4. repeat

Keep the previous look one setting or one revert away. Users often decide the
old version was better.

## 6. Finish

- Let the user try it: install or run the result for them, and point them at
  the hard states from the capture plan.
- Write down the design decisions where future work will see them, in
  `DESIGN.md` or the project's design doc, so later changes keep the
  direction. Link it from `CLAUDE.md` or `AGENTS.md`.
- Report:
  - the score trajectory (round, headline, mean)
  - what moved the score most
  - what is left, and what it would take
- If the user wants it landed, continue with `ship-it`.
