# Good Vibes Only

A multi-harness agent plugin repository (Claude Code, Codex and Antigravity)
with one plugin, `good-vibes-only`. Each skill is a folder in
`plugins/good-vibes-only/skills/` with a `SKILL.md` for agents and a
`README.md` for people. See [CONTRIBUTING.md](CONTRIBUTING.md).

## Verify

- `scripts/check-plugins.sh`: both marketplaces, both plugin manifests
  (`plugin.json` and `.claude-plugin/plugin.json`), version sync, skill
  frontmatter and relative links.
- `git ls-files -z '*.sh' | xargs -0 shellcheck`
- `tests/build-verification-environment.sh`: offline tests for `lock.sh`.
- `claude plugin validate .` and `claude plugin validate plugins/good-vibes-only`
- `agy plugin validate --strict plugins/good-vibes-only` (when `agy` is installed)
- Codex offline load check: `CODEX_HOME=$(mktemp -d) codex plugin marketplace add "$PWD"`
  then `codex plugin add good-vibes-only@good-vibes-only` (when `codex` is installed)
- README images: `scripts/readme-shots.sh` and
  `python3 assets/src/fan-out-diagram.py`, then look at every image in light
  and dark, and at the rendered README on the branch's GitHub page.

## Ship

- **Verify:** the checks above. CI runs all of them except Codex and the README
  images (Antigravity runs without `--strict` in CI).
- **Review:** skip review-loop. The user reviews every PR here themselves.
- **Merge:** rebase only (`gh pr merge --rebase`). GitHub deletes the branch.
  Bump `version` in both `plugins/good-vibes-only/plugin.json` and
  `plugins/good-vibes-only/.claude-plugin/plugin.json` when a skill's behaviour
  changes: minor for new or changed behaviour, patch for fixes.
- **After merge:** update the plugin on every machine the user works on, as
  their own instructions list them, for each installed harness:
  - Claude Code: `claude plugin marketplace update good-vibes-only && claude plugin update good-vibes-only@good-vibes-only`
  - Codex: `codex plugin marketplace upgrade good-vibes-only` (when installed)
  - Antigravity: `agy plugin install https://github.com/dinooo13/good-vibes-only/tree/main/plugins/good-vibes-only` (when installed)
  Name any machine you couldn't reach.
- **Live check:** on each machine, each installed CLI (`claude plugin list`,
  `codex plugin list`, `agy plugin list`) shows the new version.
