---
name: build-verification-environment
description: Set up a repo so agents can verify their own work without a human: a build script, a demo or seed mode, scripted screenshots, fixtures and a benchmark with a baseline, a CLI into the core, CI checks that keep docs honest, a lock for shared hardware, and the `## Verify` and `## Ship` sections that verify and ship-it read. Use when the user says "build a verification environment", "set up a harness", "make this verifiable", "so you can test it yourself" or "keep the script", or when verify had to improvise because the repo has no `## Verify` section.
---

# Build verification environment

Make proof cheap, repeatable and honest. Executable checks come first:
scripts, flags, fixtures and CI. An agent clicking through the app is the
fallback for what can't be scripted.

## 1. Audit

List what exists: scripts and package or Makefile targets, flags and env
switches, fixtures and seed data, CI jobs, CLAUDE.md or AGENTS.md rules, and
throwaway scripts that recent threads left in `/tmp` or scratchpads. Note
what the user runs here (an app, a dev server, a port, a simulator) and
which hardware agents share (GPU, Neural Engine, a simulator).

## 2. Plan

Show a table (piece, command, why, effort) and wait for the user's go, then
build the whole plan. Skip what the repo doesn't need.

- **Build and install your own copy.** `scripts/build.sh`, idempotent, with
  its exit code as the contract. It never replaces the user's copy unless
  asked. (pladder `scripts/bundle.sh`, habit-tracker
  `scripts/setup-agent-env.sh`)
- **Deterministic state.** A launch arg, URL param or env var puts the real
  UI in a known state, with stand-ins for hardware, network and models, and
  a scratch data dir. Expose a ready signal. Keep it out of release builds.
  (pladder `--overlay-demo`, a WebGL demo's `?shot=` with `window.__ready`,
  yugioh-alpha `NUXT_E2E_SEED_CATALOG`, Debug-only sample scans in an iOS app)
- **Demo data.** Fictional, believable and committed, written by a seed
  script. Never real user data. (habit-tracker demo JSON)
- **Shoot every screen.** `scripts/shoot.*` captures every screen and the
  hard states, at fixed sizes and in light and dark, into a gitignored dir.
  For motion, add contact sheets. (pladder `make-screenshots.sh` and
  `overlay-demo.sh`, a script that renders each shot beside its reference)
- **Fixtures and a benchmark.** Generated fixtures, a warm-up, an idle pause,
  median and spread, and the load recorded. Set a noise threshold and keep
  the baseline in `docs/BENCHMARKS.md`. (pladder `make-fixtures.sh` and
  `pladder-cli bench`)
- **A CLI into the core.** Run the core logic on a file or input without the
  UI. (pladder `pladder-cli --process`, a headless physics sim for a game)
- **A lock.** Only for repos that time things on shared hardware: copy
  [`scripts/lock.sh`](scripts/lock.sh) and wrap every bench with it, as in
  `scripts/lock.sh gpu -- npm run bench`.

Per platform:
- **macOS:** stand-in drivers, a screen recording cut into contact sheets,
  and kill only by your own build's path.
- **iOS and Flutter:** Debug-only seed data, one pinned simulator through the
  T3 device tools, the simulator's limits written down, and a checklist for
  the human on a real device.
- **Web:** a seed env, its own e2e port and DB per agent, a preview per PR, a
  prod smoke test on the deployed SHA, and Lighthouse against a static build.
- **WebGL and games:** shot presets, references plus look metrics, an
  in-page perf A/B, and capture inside the page. Measure fps only on an idle
  GPU.

Repo scripts may use Playwright so they also run in CI. When an agent checks
by hand inside T3, it uses the T3 preview browser before `playwright-cli`.

## 3. Build

One commit per piece. Run each script and look at its output before moving
on. Move useful throwaway scripts into `scripts/` under real names. Every
script answers `--help`.

## 4. Write the rules

Add to `CLAUDE.md`, or `AGENTS.md` if that is the one the repo uses:
- **`## Verify`:** the command for each kind of change, the hard states,
  where output lands, the lock names, and what only a human can check.
- **`## Ship`:** the lines `Verify`, `Merge`, `After merge` and `Live check`.
- **`## Working next to the user`:** their copy, port, data and simulator
  stay untouched; stop only what you started, by path or PID; no synthetic
  global input.

## 5. Guard it in CI

Cheap checks that keep it true: every script's `--help` runs, the flags the
docs name exist, doc pointers and site numbers resolve, a grep fails on
`killall` or `pkill -x` of the app, and a watchdog samples a hung test.
macOS and iOS repos may get a macOS runner. (pladder `check-site-numbers.sh`,
`check-doc-pointers.sh`, `scripts.yml`)

## 6. Prove and hand over

Check the setup with a fresh subagent: it may read only `## Verify`, and it
runs `verify` on one real screen and one bench. Fix what it trips over.
Report what is covered and what still needs a human, then land it with
`ship-it`.

## Never

- Kill, relaunch or reconfigure the user's running app, dev server or
  simulator, or touch their data.
- Put real personal data, secrets or credentials in fixtures, seeds, scripts
  or package files.
- Ship a demo mode or stand-ins in release builds.
- Run benchmarks in parallel, or trust numbers measured under contention.
- Change product behaviour, or weaken a test to make a check pass.
- Install system packages with sudo. Give the user the command instead.
