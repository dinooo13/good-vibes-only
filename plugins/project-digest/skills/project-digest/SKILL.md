---
name: project-digest
description: A short digest of the user's GitHub projects. It covers new issues and comments from other people, PRs that are ready to merge, failing, behind or waiting for review, red CI on default branches, the user's own open PRs in other people's repos, and unreleased commits. Read only. Use when the user asks "what's going on in my repos", "status of my projects", "anything I need to look at", or when a scheduled task runs it.
---

# Project digest

Tell the user what needs them, in under a minute of reading. Silence is fine:
if nothing needs them, say so in one line.

Read only. Never comment, label, merge, rerun or close anything.

## 1. Scope

- **Repos:** the ones listed in the prompt. Otherwise, the user's own repos
  pushed in the last 30 days:
  `gh repo list --limit 50 --json nameWithOwner,pushedAt,isArchived`.
  Skip archived repos and forks unless they are listed.
- **The user:** `gh api user --jq .login`.
- **Since when:** the time of the last digest, from
  `~/.local/state/good-vibes-only/digest-last-run` (an ISO timestamp).
  Without that file, use 24 hours, or 72 hours on a Monday. Write the new
  timestamp at the end of a successful run.

## 2. Collect

Prefer one `gh` call per question across all repos, or one per repo, with
`--json` and `--jq`.

- **People waiting on the user:**
  - issues and comments from anyone but the user and bots since then, across
    issues and PRs:
    `gh search issues --owner <owner> --updated ">=<date>" --json …`,
    then the comments per hit
  - review requests: `gh search prs --review-requested @me --state open`
  - first-time contributors and first issues from new people. Mark them; they
    matter more.
- **The user's open PRs:**
  `gh pr list --author @me --json number,title,mergeStateStatus,reviewDecision,statusCheckRollup,isDraft`.
  For each, the state: ready to merge, failing, behind or conflicting, changes
  requested, or waiting.
- **The user's PRs in other people's repos:**
  `gh search prs --author @me --state open`, minus the user's own repos.
  Include new comments, reviews and CI results, and whether the PR fell behind
  its base.
- **Default branches:** the latest workflow run on main
  (`gh run list --branch <default> --limit 3 --json conclusion,name,createdAt,url`).
  Report it only if it's red.
- **Unreleased work:** for repos that cut releases, the number of commits on
  the default branch since the latest release
  (`gh release view --json tagName`, then `gh api repos/<r>/compare/<tag>...<default>`).
  Mention it only when there's something worth releasing.

If GraphQL is rate limited, use REST (`gh api repos/<owner>/<repo>/…`).

## 3. Write the digest

Group the lines and skip empty groups:

```markdown
**Needs you**
- <repo>#<n> <title>: <who> <did what> <when>. <link>

**Broken**
- <repo>: main is red (<workflow>). <link>
- <repo>#<n> is behind main or has conflicts. <link>

**Ready**
- <repo>#<n> <title>: all checks green, reviews done. Ready to merge. <link>

**FYI**
- <repo>: 7 commits since v0.2.0.
```

- One line per item. Name the person, and say what they want.
- End with at most three suggested next steps that fit the user's skills, for
  example "fan-out pladder#111" or "ship-it pladder#114".
- If nothing needs the user: "Nothing needs you since <time>."
