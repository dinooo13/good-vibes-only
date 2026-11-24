# Good Vibes Only

A Claude Code plugin marketplace with one plugin, `good-vibes-only`. Each skill
is a folder in `plugins/good-vibes-only/skills/` with a `SKILL.md` for Claude
and a `README.md` for people. See [CONTRIBUTING.md](CONTRIBUTING.md).

## Verify

- `scripts/check-plugins.sh`: manifests and skill frontmatter.
- `git ls-files -z '*.sh' | xargs -0 shellcheck`
- `tests/build-verification-environment.sh`: offline tests for `lock.sh`.
- `claude plugin validate .` and `claude plugin validate plugins/good-vibes-only`
- README images: `scripts/readme-shots.sh` and
  `python3 assets/src/fan-out-diagram.py`, then look at every image in light
  and dark, and at the rendered README on the branch's GitHub page.

## Ship

- **Verify:** the checks above. CI runs all of them except the README images.
- **Merge:** rebase only (`gh pr merge --rebase`). GitHub deletes the branch.
  Bump `version` in `plugins/good-vibes-only/.claude-plugin/plugin.json` when
  a skill's behaviour changes: minor for new or changed behaviour, patch for
  fixes.
- **After merge:** update the plugin on every machine the user works on, as
  their own instructions list them:
  `claude plugin marketplace update good-vibes-only && claude plugin update good-vibes-only@good-vibes-only`.
  Name any machine you couldn't reach.
- **Live check:** on each machine, `claude plugin list` shows the new version.
