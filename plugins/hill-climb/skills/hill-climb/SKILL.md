---
name: hill-climb
description: Improve something round by round until an independent critic scores it at or above a target out of 10, for UI and UX, visual fidelity against references, a game scene, copy or a site. A fresh critic captures the current state, scores it with a fixed rubric and ranks the defects; implementers fix the top ones; repeat. Use when the user gives a target score ("keep iterating until the reviewer gives at least 9"), says "hill climb", or asks for critic rounds. Pairs well with /goal. Not for code review; that is review-loop.
---

# Hill climb

A fresh critic scores the work every round with the same rubric. You fix what
holds the score down and go again. The climb stops at the target, at a
plateau, or when the budget runs out.

## Setup

Put these in `hill-climb/`. Commit the rubric, the scores and the critiques.
Gitignore `captures/` and `reference/`. Show the setup to the user unless they
already said go.

- **Target and budget:** for example a headline of at least 9.0 within 8
  rounds, plus any pause points the user wants.
- **References:** check that they show what the user means. Gameplay, not a
  trailer; the real app, not marketing renders. If you can't fetch one, ask
  for screenshots.
- **Rubric:** 5 to 10 axes scored 0–10, each with anchors for 5, 7 and 9.
  Add one holistic headline axis that the target applies to, such as "same
  game" or "feels first-party". Easy metrics like colour statistics never
  stand in for it.
- **Capture plan:** fixed shots, captured the same way every round. It
  includes the hard states:
  - everything switched on
  - the longest text
  - the smallest and largest window
  - empty and error states
  - light and dark
  - motion, not only stills
- **For `/goal`:** the condition is that the last two critiques, from
  different critics, both reach the target.

## Each round

1. **Critic.** Start a new `delegate_task` (`role: "review"`) with the newest
   Fable or Opus at `xhigh`. Never reuse a critic.
   - **Give it** the rubric, the references, the capture plan, the commit to
     judge, and the round 1 critique for calibration.
   - **Never tell it** the target or what you hope for.
   - **The task text says** to make its own captures (preview browser, device
     tools, or the built app), to write only under `hill-climb/critiques/` and
     `hill-climb/captures/`, and never to touch the source.
   - **It returns:**
     - the score per axis, with the change since the last round
     - the headline score
     - whether each claimed fix is fixed, partly fixed or not fixed
     - new regressions
     - up to 10 defects ranked by gain per effort, each with a concrete fix
2. **Score.** Append the round, the commit, the headline and the mean to
   `hill-climb/scores.md`.
3. **Fix.** Cluster the defects and give each cluster to one implementer:
   Sonnet for clear fixes, Opus `high` for judgement. Give them worktrees or
   disjoint files. Integrate, build, and commit a snapshot for the next critic.
4. **Measure one at a time.** Measurements on shared hardware (GPU, Neural
   Engine, a simulator) need a lock. Put these rules in each implementer's
   task text:
   - Take the lock with `mkdir /tmp/<repo>-<resource>.lock`, and put an
     `owner` file inside it.
   - If it's taken, wait with one background `until mkdir …; do sleep 30; done`.
   - Release it with `rm -r`, and never break someone else's lock.

   Fix the real defect, not the metric. If the headline drops, fix that
   first.

## Stopping

- **The target is reached:** run one confirmation round with another fresh
  critic.
- **A plateau:** two rounds in a row add less than 0.2. Report what blocks
  progress.
- **The budget or a pause point is reached, or usage is near its limit.** Load
  `usage-limits` if it's installed; `scores.md` is the handoff.

If the user changes the target mid-run, follow it.

When what's left is taste (how a motion feels), stop the critic rounds. Run
short loops with the user instead: install, ask one question, change one
thing, keep the old version one revert away.

At the end, install or run the result for the user, and point them at the hard
states. Write the design decisions into `DESIGN.md` and link it from
`CLAUDE.md`. Report the score trajectory, what moved it, and what's left. Land
it with `ship-it` if they ask.
