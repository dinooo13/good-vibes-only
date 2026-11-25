# Good Vibes Only ✌️

Thirteen agent workflow skills for Claude Code, Codex and Antigravity that take your agents' work from "done, I think" to merged, deployed and checked live. You stop babysitting and start reviewing plans.

[![Claude Code](https://img.shields.io/badge/Claude_Code-plugin-d97757)](#install)
[![Codex](https://img.shields.io/badge/Codex-plugin-10a37f)](#install)
[![Antigravity](https://img.shields.io/badge/Antigravity-plugin-4285f4)](#install)
[![Best in T3 Code](https://img.shields.io/badge/best_in-T3_Code-6e40c9)](https://github.com/pingdotgg/t3code)
[![CI](https://github.com/dinooo13/good-vibes-only/actions/workflows/ci.yml/badge.svg)](https://github.com/dinooo13/good-vibes-only/actions/workflows/ci.yml)
[![MIT license](https://img.shields.io/badge/license-MIT-2ea043)](LICENSE)

<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="assets/project-digest-dark.png">
    <img src="assets/project-digest-light.png" width="680" alt="The project-digest page in T3 Code for the maintainer's repos: a first-time issue on ygo-alpha waiting for a reply, pladder's four open issues with the chain #123 to #125 and #126, quiet repos, and two skills to run next: fan-out on pladder#123 and #124, and pr-comments on ygo-alpha#176.">
  </picture>
  <br>
  <sub>A Tuesday morning in my own repos, as project-digest shows it in T3 Code.</sub>
</p>

## Install

**Claude Code**

```
/plugin marketplace add dinooo13/good-vibes-only
/plugin install good-vibes-only@good-vibes-only
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

That's it. Your agent picks a skill from what you say, or you call one by name (`/good-vibes-only:ship-it` in Claude Code, `$ship-it` in Codex, `/ship-it` in Antigravity).

They work in any standalone session and shine in [T3 Code](https://github.com/pingdotgg/t3code), where they get threads, agents on other providers, PR watching, a preview browser, simulators and schedules.

## Why you'll like it

- **"Ship it" means shipped.** Proof, a fresh review, CI, review bots, rebases, the merge, the deploy and a look at it live. Not "PR opened, good luck".
- **A fresh review before the PR.** Unless you skip it, ship-it hands each change to two reviewers from different model families, Opus and Gemini, with no shared history, so nothing gets waved through. It goes round after round until they approve, or brings three providers at once when you say "council".
- **Five issues, one approval.** fan-out gives each issue its own thread and worktree. You approve all the plans in one place, and each comes back as its own merged PR.
- **Proof you can see.** The change working in the browser, the simulator or the real app, including the long text, the phone width and dark mode. Not a wall of green mocked tests.
- **Mornings start with a list.** Who's waiting on you, where every issue stands, and what to start next, like the page above.

## The lineup

Click a skill for what it does in detail.

| Skill | Say | You get |
| --- | --- | --- |
| **Land changes** | | |
| [ship-it](plugins/good-vibes-only/skills/ship-it) | "ship it", "merge when green" | Proof, a review loop, PR, babysitting, rebase, merge, deploy, a live check, cleanup |
| [almost-ship-it](plugins/good-vibes-only/skills/almost-ship-it) | "almost ship it", "ship it but don't merge" | All of ship-it up to the merge, then a PR ready for you to merge |
| [review-loop](plugins/good-vibes-only/skills/review-loop) | "review loop", "council" | Fresh reviewers, round after round, until they approve |
| [verify](plugins/good-vibes-only/skills/verify) | "verify yourself" | Proof you can see: browser, simulator, the real app, the hard states |
| [build-verification-environment](plugins/good-vibes-only/skills/build-verification-environment) | "build a verification environment" | Build script, demo mode, scripted screenshots and benchmarks, so agents check their own work |
| [pr-comments](plugins/good-vibes-only/skills/pr-comments) | "draft a reply on the PR" | Short comments in your voice, shown as drafts before people see them |
| **Let agents run on their own** | | |
| [fan-out](plugins/good-vibes-only/skills/fan-out) | "fan out issues 36, 37 and 38" | One thread per issue: plan, your go, implement, verify, review, ship |
| [handoff](plugins/good-vibes-only/skills/handoff) | "write a handoff" | A brief that lets a new thread carry on without your history |
| [hill-climb](plugins/good-vibes-only/skills/hill-climb) | "iterate until the reviewer gives at least 9" | Critic rounds with a fixed rubric until the score hits the target |
| **Keep tabs** | | |
| [project-digest](plugins/good-vibes-only/skills/project-digest) | "anything I need to look at?" | Who's waiting on you, where every issue stands, what to start next |
| [tidy-repos](plugins/good-vibes-only/skills/tidy-repos) | "clean up branches" | Merged branches and clean worktrees gone, stale work listed |
| **Polish the product** | | |
| [product-readme](plugins/good-vibes-only/skills/product-readme) | "make the README sell it" | A README that sells, like this one |
| [web-quality](plugins/good-vibes-only/skills/web-quality) | "check the Core Web Vitals" | Lighthouse, SEO and GEO, and a visual pass, before and after |

## How they team up

The skills call each other, which is why they come as one plugin. ship-it proves changes with verify, reviews them with review-loop and answers bots with pr-comments. verify runs the scripts that build-verification-environment set up. fan-out writes its briefs with handoff and lands every issue with ship-it, which runs verify, review-loop and the PR in one go:

<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="assets/fan-out-dark.svg">
    <img src="assets/fan-out-light.svg" width="900" alt="fan-out: a request for issues 36 to 38 becomes three issue threads. Each runs plan, your go and implement, then ship-it, which runs verify, review-loop and the PR until it merges. The three plans are approved in one place, and each issue ends as its own PR.">
  </picture>
</p>

## FAQ

**Do I need T3 Code?**
No. Every skill runs standalone in Claude Code, Codex or Antigravity and falls back where it can: verify drives the browser with `playwright-cli`, review-loop runs your current provider's reviewer as a plain subagent, and fan-out runs one isolated worktree per issue. Cross-provider reviewers (such as Opus and Gemini side by side) need T3.

**Will it merge or post anything without asking?**
Only what you asked for. "Ship it" allows a merge, and only after verify proved the change and a review loop signed off; say "skip the review" for a change that doesn't need one. "Almost ship it" does all of that and stops with the PR ready for you to merge. Comments a person will read are shown to you as drafts first. project-digest is read only, tidy-repos never deletes unmerged work, and product-readme touches the repo description only after your OK.

**Which models does it use?**
The newest of each family, never hardcoded IDs: Opus and Gemini Neon at xhigh review side by side, and Fable plans and Opus builds in fan-out. Name other models in your request or your `CLAUDE.md` / `AGENTS.md` and they win.

**How do I update?**
- Claude Code: `claude plugin marketplace update good-vibes-only && claude plugin update good-vibes-only@good-vibes-only`
- Codex: `codex plugin marketplace upgrade good-vibes-only`
- Antigravity: `agy plugin install https://github.com/dinooo13/good-vibes-only/tree/main/plugins/good-vibes-only`

## Credits

Several skills borrow ideas from Theo's [tstack](https://github.com/t3dotgg/tstack): review-loop from `council` and `sol-loop`, ship-it from `babysit-pr` and `full-send`, almost-ship-it from `full-stop`, and pr-comments from `leaving-pr-comments`.

Want to change a skill? See [CONTRIBUTING.md](CONTRIBUTING.md).

[MIT](LICENSE) © Fabian Meyer
