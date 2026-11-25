# Install and setup

Good Vibes Only ships as a single plugin with both an [Agent Plugins 1.0.0](https://agent-plugins.org/) manifest (`plugins/good-vibes-only/plugin.json`) and a Claude Code manifest (`plugins/good-vibes-only/.claude-plugin/plugin.json`).

## Install

**Claude Code**

Inside a Claude Code session:

```
/plugin marketplace add dinooo13/good-vibes-only
/plugin install good-vibes-only@good-vibes-only
```

Or from your terminal:

```bash
claude plugin marketplace add dinooo13/good-vibes-only
claude plugin install good-vibes-only@good-vibes-only
```

**Codex**

```bash
codex plugin marketplace add dinooo13/good-vibes-only
codex plugin add good-vibes-only@good-vibes-only
```

**Antigravity**

```bash
agy plugin install https://github.com/dinooo13/good-vibes-only/tree/main/plugins/good-vibes-only
```

Other Agent Plugins 1.0.0 compatible harnesses can point at `plugins/good-vibes-only`.

## Update

**Claude Code**

```bash
claude plugin marketplace update good-vibes-only
claude plugin update good-vibes-only@good-vibes-only
```

**Codex**

```bash
codex plugin marketplace upgrade good-vibes-only
```

**Antigravity**

```bash
agy plugin install https://github.com/dinooo13/good-vibes-only/tree/main/plugins/good-vibes-only
```

Check the installed version with `claude plugin list`, `codex plugin list`, or `agy plugin list`.

## Calling a skill

Your agent picks a skill automatically from natural language (for example "ship it" or "anything I need to look at?"). To invoke one directly:

| Harness | Direct invocation |
| --- | --- |
| Claude Code | `/good-vibes-only:ship-it` |
| Codex | `$ship-it` |
| Antigravity | `/ship-it` |

## Standalone vs T3 Code

Every skill works in a standalone session and upgrades automatically when [T3 Code](https://github.com/pingdotgg/t3code) tools are available:

| Capability | Standalone | In T3 Code |
| --- | --- | --- |
| PRs, CI checks and issues | `gh` CLI | Native `pull_request_*`, `ci_*` and issue tools, plus `watch_pull_request` |
| Code reviews (`review-loop`) | Native subagent on your current provider | Parallel fresh reviewers across providers (Opus + Gemini, or three-provider `council`) |
| Multi-issue orchestration (`fan-out`) | One isolated worktree per issue, stops before merge | One T3 thread + worktree per issue, single approval round, merges in dependency order |
| Web verification (`verify`, `web-quality`) | `playwright-cli` | Shared T3 preview browser (`preview_*`) |
| Simulators and emulators (`verify`) | Project CLI tools | T3 Device panel (`device_*`) |
| Morning digest (`project-digest`) | Structured Markdown | Rendered HTML page inline in the thread, plus scheduled runs |

## Prerequisites

Only install what the skills you use actually call:

- **GitHub CLI (`gh`)** — authenticated (`gh auth status`), used by `ship-it`, `almost-ship-it`, `pr-comments`, `project-digest`, `tidy-repos`, `fan-out` and `product-readme` (outside T3 and as fallback inside T3).
- **`playwright-cli`** — needed by `verify` and `web-quality` when running web checks outside T3 Code.
- **Node / `npx`** — runs `npx lighthouse` for `web-quality`.
- **`ffmpeg`** — converts screen recordings to GIFs in `product-readme`.

## Project setup (optional)

- **Verification and shipping rules:** `verify` and `ship-it` read `## Verify` and `## Ship` from your repo's `AGENTS.md` or `CLAUDE.md`. Run `build-verification-environment` in any repo to set up scripts, fixtures and both sections for you.
- **Ignoring repos in `project-digest`:** create `~/.config/good-vibes-only/digest.json` with `{ "ignore": ["owner/repo"] }` to skip demo or course repos.
- **Custom models:** default reviewers and planners pick the newest model in each family without hardcoded IDs. Name different models in your prompt or your repo's `AGENTS.md` / `CLAUDE.md` to override them.

## Uninstall

**Claude Code**

```bash
claude plugin uninstall good-vibes-only@good-vibes-only
claude plugin marketplace remove good-vibes-only
```

**Codex**

```bash
codex plugin remove good-vibes-only@good-vibes-only
codex plugin marketplace remove good-vibes-only
```

**Antigravity**

```bash
agy plugin uninstall good-vibes-only
```
