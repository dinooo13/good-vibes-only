---
name: project-digest
description: A short, read-only digest of the user's GitHub projects. It covers who is waiting on the user (however old), the open issues per repo with their status and dependencies, PRs that are ready, failing, behind or waiting for review, red CI on default branches, the user's open PRs in other people's repos, unreleased commits, and what to kick off next. In T3 Code it shows the digest as an HTML page. Use when the user asks "what's going on in my repos", "anything I need to look at", "what could I work on next", or for a status of their projects, and when a scheduled task runs it.
---

# Project digest

Tell the user what needs them, where every open issue stands, and what to
start next, in under a minute of reading. If nothing needs them, say so in one
line. This is read only: never comment, label, merge, rerun or close anything.

## Scope

- **Repos:** the ones in the prompt. Otherwise, the user's own repos pushed in
  the last 30 days, without archived repos and forks:
  `gh repo list --limit 50 --json nameWithOwner,pushedAt,isArchived,isFork,defaultBranchRef`.
- **Ignored repos:** `~/.config/good-vibes-only/digest.json`, if it exists,
  holds `{ "ignore": ["owner/name", …] }`. Skip those repos entirely: no
  issues, PRs, CI or release checks, and drop them from search results. A
  repo the prompt names is read anyway.
- **Since:** the timestamp in `~/.local/state/good-vibes-only/digest-last-run`,
  or 24 hours (72 on a Monday) if the file doesn't exist. After a full or
  scheduled run, store the time the run started, so nothing that arrives
  during the run is lost. A one-off digest of a single repo doesn't update
  it.

The window only decides what counts as new. Open issues, open PRs and people
waiting on the user are listed however old they are.

## Collect

Per repo, read all open issues and PRs, not only recent ones. Loop with
`… --jq '.[].nameWithOwner' | while read -r r; do …; done`: zsh doesn't split
an unquoted `$REPOS`.

- **Open issues:** fetch open issues once per repo (e.g.
  `gh api "repos/<r>/issues?state=open&per_page=100"`, filtering out items
  with `pull_request`, which includes `author_association`; use GraphQL or
  `gh issue list` only when you also need native `blockedBy` links).
  Give each a status; the first that fits wins:
  - **PR #N in review** or **PR #N green, draft**: an open PR lists it in
    `closingIssuesReferences`, or says "closes #N" or "(#N)" in its title or
    body.
  - **Unanswered**: someone other than the user (`gh api user --jq .login`)
    opened it, not a bot, and the user hasn't commented.
  - **Needs your yes**: the body asks for the maintainer's approval, or a
    label says so.
  - **Blocked by #N**: `blockedBy`, or the body's `## Blocked by` section,
    names an issue that is still open.
  - **Ready to start**: nothing above applies.

  Note the dependency chains, like `#123 → #125 + #126`.
- **Open PRs:** `gh pr list -R <r> --json number,title,author,isDraft,mergeStateStatus,reviewDecision,statusCheckRollup,closingIssuesReferences,url`.
  Classify the user's own as ready, failing, behind or conflicting, changes
  requested, or waiting. A PR from someone else waits on the user when it has
  no review from them, or no checks have run
  (`gh api "repos/<r>/actions/runs?status=action_required"`).
- **New activity:** comments since the last run from anyone except the user
  and bots (`gh search issues --owner <owner> --updated ">=<date>" --include-prs`),
  and open review requests.
- **First-timers:** `author_association` NONE, FIRST_TIME_CONTRIBUTOR or
  FIRST_TIMER.
- **The user's PRs elsewhere:** `gh search prs --author @me --state open`,
  outside their own repos. Note new reviews, CI results, and whether the PR
  fell behind its base.
- **Default branches:** the latest run of each workflow on the default branch
  (`gh run list -R <r> --branch <default> --limit 50 --json workflowName,conclusion,url,createdAt`,
  newest per `workflowName`). A repo is green only when all of them are.
- **Unreleased work:** the commits on the default branch since the last
  release, in repos that cut releases.

If GraphQL is rate limited, use `gh api repos/…` (REST).

## Sort it

- **Needs you**, however old: unanswered issues and PRs from other people
  (flag first-timers), PRs from others waiting on a review or CI approval,
  issues that ask for the user's decision, red default branches, and the
  user's failing PRs.
- **Open issues by repo**, with the statuses and chains above. Repos with no
  open issues and green CI go in one quiet line.
- **Your PRs:** ready, behind or waiting, here and in other people's repos.
- **Kick off next:** at most three, as skill calls, like
  `fan-out pladder#123`, `pr-comments ygo-alpha#176` or
  `ship-it pladder#114`. Rank what unblocks the most first, then people
  waiting, then PRs that are nearly done. Give each a one-line reason. If a
  repo's issues look like they're for someone else, such as course teams with
  `team-3` or `kurs/*` branches, say so and suggest adding it to the ignore
  list.

## Show it

**In T3 Code:** fill in [digest-template.html](digest-template.html). Keep its
styles and replace every sample row; none of them is real. Every row links to
GitHub, and empty sections are left out. End with one muted line naming the
ignored repos, if there are any. Pass the HTML inline to `html_preview` and
`html_render` (or write it to `/tmp/project-digest.html`). The text reply says
only what the page doesn't, such as errors or repos that couldn't be read.

**Elsewhere,** write text with the same sections (**Needs you**, **Open issues
by repo**, **Your PRs**, **Kick off next**, plus a quiet-repos line), skipping
empty ones. Write one line per item with a link, saying who did what.
