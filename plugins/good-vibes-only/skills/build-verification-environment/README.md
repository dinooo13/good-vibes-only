# build-verification-environment

Build script, demo mode, scripted shots, benchmarks and CI checks, so agents can prove their own work.

**Say:** "build a verification environment"

verify is only as good as the tools a repo gives it, and this skill builds them. It audits what's there and proposes a plan for the platform. Once you say go, it adds:
- a build script
- a demo mode with fictional seed data
- scripted screenshots of every screen in light and dark
- fixtures and a benchmark with a baseline
- a CLI into the core logic
- CI checks that keep the docs and numbers honest

It also writes the `## Verify` and `## Ship` sections that verify and ship-it read, and a fresh agent that sees only `## Verify` tries the setup before handover. Repos that benchmark get `scripts/lock.sh`, so parallel agents take turns on shared hardware instead of measuring each other. It never touches the copy of the app you're running, and it never puts real data in fixtures.

---

Part of [Good Vibes Only](../../../../README.md). The instructions the agent follows are in [SKILL.md](SKILL.md).
