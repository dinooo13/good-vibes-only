# Contributing

Each skill is a folder in `plugins/good-vibes-only/skills/` with a `SKILL.md`
for agents, a `README.md` for people, and anything it ships, like scripts or
templates. Its frontmatter `description` decides when an agent picks it up,
so keep the trigger phrases in it current.

Each plugin ships both `plugin.json` (Agent Plugins 1.0.0, read by Codex and
Antigravity) and `.claude-plugin/plugin.json` (read by Claude Code); keep
their `name`, `version` and `description` in sync.

## Before a push

```
scripts/check-plugins.sh                 # manifests, marketplaces and skills
tests/build-verification-environment.sh  # offline tests for lock.sh
```

CI runs both, plus ShellCheck on every `*.sh`, Claude Code's plugin validator
and Antigravity's plugin validator.

## README screenshots

The screenshots in `assets/` come from pages in `assets/src/`, filled in by
hand from the maintainer's public repos. Leave out other people's handles and
anything from private repos. After changing a page, or the project-digest
template it copies its styles from, run:

```
scripts/readme-shots.sh
```

It renders each page in light and dark at 2x with Playwright's headless
Chromium. The fan-out diagram is drawn by `python3 assets/src/fan-out-diagram.py`.
Look at every image before you commit it.
