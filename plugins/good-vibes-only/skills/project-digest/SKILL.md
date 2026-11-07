---
name: project-digest
description: A short, read-only digest of the user's GitHub projects. It covers new issues and comments from other people, PRs that are ready, failing, behind or waiting for review, red CI on default branches, the user's open PRs in other people's repos, and unreleased commits. Use when the user asks "what's going on in my repos", "anything I need to look at", or for a status of their projects, and when a scheduled task runs it.
---

# Project digest

Tell the user what needs them in under a minute of reading. If nothing does,
say so in one line. This is read only: never comment, label, merge, rerun or
close anything.

## Scope

- **Repos:** the ones in the prompt. Otherwise, the user's own repos pushed in
  the last 30 days, without archived repos and forks:
  `gh repo list --limit 50 --json nameWithOwner,pushedAt,isArchived,isFork`.
- **Since:** the timestamp in `~/.local/state/good-vibes-only/digest-last-run`,
  or 24 hours (72 on a Monday) if the file doesn't exist. After a full or
  scheduled run, store the time the run started, so nothing that arrives
  during the run is lost. A one-off digest of a single repo doesn't update
  it.

## Collect

- **People waiting on the user:** new issues and comments from anyone except
  the user (`gh api user --jq .login`) and bots
  (`gh search issues --owner <owner> --updated ">=<date>" --include-prs`). Also open review
  requests. Mark first-time contributors.
- **The user's PRs:** `gh pr list --author @me --json` with
  `mergeStateStatus`, `reviewDecision` and `statusCheckRollup`. Classify each
  as ready, failing, behind or conflicting, changes requested, or waiting.
- **The user's PRs elsewhere:** `gh search prs --author @me --state open`,
  outside their own repos. Note new reviews and CI results, and whether the PR
  fell behind its base.
- **Default branches:** the latest run on main; list it only if it's red.
- **Unreleased work:** the commits on main since the last release, in repos
  that cut releases.

If GraphQL is rate limited, use `gh api repos/…` (REST).

## Write it

Use the groups **Needs you**, **Broken**, **Ready** and **FYI**, and skip
empty ones. Write one line per item with a link, saying who did what. End with
at most three next steps, such as "fan-out pladder#111" or
"ship-it pladder#114".
