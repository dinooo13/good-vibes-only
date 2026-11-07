# Good Vibes Only ✌️

Claude Code plugins that give your agents good vibes. Useful skills that take care of the annoying parts of agent work, so your agents can stay on track and you don't have to babysit them.

```
/plugin marketplace add dinooo13/good-vibes-only
/plugin install usage-limits@good-vibes-only
/plugin install good-vibes-only@good-vibes-only
```

Two plugins: `usage-limits` keeps long runs alive, and `good-vibes-only` bundles the workflow skills below. They're bundled because they lean on each other: ship-it proves changes with verify and answers bots with pr-comments, and fan-out hands every PR to review-loop and ship-it. Claude picks them up from what you say, or you call them directly, for example `/good-vibes-only:ship-it`.

The workflow skills are made for [T3 Code](https://github.com/pingdotgg/t3code). They use its tools for threads, delegated agents, PR watching, the preview browser and scheduled tasks. Elsewhere they fall back to the harness's own subagent and browser tools.

## The lineup

| Skill | Say | What happens |
| --- | --- | --- |
| [ship-it](#ship-it) | "ship it" | Verify, PR, babysit, rebase, merge, pull main, install or deploy, check live, clean up |
| [review-loop](#review-loop) | "review loop", "council" | A fresh Opus xhigh reviewer reviews; you fix; repeat until it approves |
| [fan-out](#fan-out) | "fan out issues 36–38" | Planners, your approval, implementers in worktrees, reviews, merges in order |
| [handoff](#handoff) | "write a handoff" | A brief that lets a new thread carry on without your history |
| [hill-climb](#hill-climb) | "until the critic gives a 9" | Critic rounds with a fixed rubric until the score reaches the target |
| [product-readme](#product-readme) | "make the README sell it" | Hero, real screenshots, short install, details moved out |
| [web-quality](#web-quality) | "check the core web vitals" | Lighthouse, SEO and GEO, and a visual pass, before and after |
| [project-digest](#project-digest) | "what needs me?" | Who's waiting on you, what's broken, what's ready to merge |
| [tidy-repos](#tidy-repos) | "clean up branches" | Merged branches and clean worktrees go; stale work gets listed |
| [verify](#verify) | "verify yourself" | Proof you can see: preview browser, simulator, the real app, the hard states |
| [pr-comments](#pr-comments) | "draft a reply" | Short comments in your voice, drafts before people see them, a note on bot replies |

### usage-limits

Nothing kills the vibe like hitting your usage limit mid-run, with half the work completed.

This skill keeps an eye on your 5-hour and 7-day usage windows while Claude works. When a limit gets close, Claude finishes the current step, commits, leaves itself a handoff note, and waits until the window resets. Then the same thread wakes up, reads the note, and carries on.

### How the waking up works:
Claude starts a background script that sleeps until the window resets, then exits. Claude Code notifies the same thread, and Claude picks up where it left off. The wait costs no tokens.

Just tell Claude to continue once your limit resets to trigger.
Claude also loads the skill on its own before long jobs.

### The hook:
Claude can't feel time passing, so the plugin adds a hook as a backstop. Every 2 minutes at most, after a tool call or when you send a message, it looks at the cached usage. It stays silent until usage gets high, then tells Claude to load the skill. The first nudge is a heads-up at 75% of the 5-hour window. At 90% of the 5-hour window, or 95% of the weekly one, it tells Claude to wrap up. The hook never waits on the network: when the cache is old, it refreshes it in the background for the next check. Set `USAGE_HOOK=0` to turn it off.

### Tuning:
By default Claude wraps up at 90% of the 5-hour window (`USAGE_WRAP_PCT`) and 95% of the weekly windows (`USAGE_WRAP_7D_PCT`). Set either one in the `env` block of `~/.claude/settings.json`. The hook, the watcher, and the checks all follow them. Leave some room: subagents keep using quota while Claude wraps up, and the hook only checks every 2 minutes.

### Requirements:
`bash`, `curl`, `jq`, and a Claude Code login with a Pro or Max subscription.

### How it knows:
Usage comes from Anthropic's OAuth usage endpoint, using the token Claude Code already stores (macOS keychain, or `~/.claude/.credentials.json` on Linux). The token goes to curl on stdin, never on a command line, and is never cached or printed.

The endpoint sometimes rate-limits requests. When that happens, every check on the machine backs off (1 minute, doubling up to 15). Meanwhile the skill asks [CodexBar](https://github.com/steipete/CodexBar) if it's installed. Otherwise it uses the last good result for up to 15 minutes, clearly marked as stale. CodexBar is optional.

### One catch:
The wait belongs to the Claude Code session. If you close the cli or the app, nothing resumes.

### ship-it

"Ship it" should mean shipped, not "PR opened, good luck". The skill proves the change before the PR, then babysits checks and review bots. It rebases when the branch falls behind and only merges once the gate is green. After the merge it pulls main, installs or deploys, and looks at the result live. Each project says how to install and deploy in a `## Ship` section of its `CLAUDE.md`. Without one, the skill proposes it.

### review-loop

A second opinion, as many times as it takes (three rounds by default). The reviewer, Opus at xhigh unless you name another, runs in its own thread with no history, gives a score out of 10, and labels each finding blocker, should or nit. You fix what's real, push back with evidence, and decline scope creep. Say "council" to get three providers at once. The scores per round end up in the PR description.

### fan-out

Hand it a handful of issues. It writes the missing "Done when" criteria, groups issues that touch the same files, and plans each one with a strong model. Then it waits for your go. Implementers work in their own worktrees, take turns on shared resources like benchmarks, and wait for the PRs they depend on. Every PR goes through review-loop and ship-it. With `--plan-only` it just posts plans on the issues, which makes a nice overnight job.

### handoff

New thread, no memory. The brief carries the task, the reasons, what's already decided, what to read, how to verify and when it's done. It prints it, saves it, launches it as a T3 thread, or turns it into a `/goal` under 4,000 characters.

### hill-climb

Give it a target ("at least 9 out of 10") and it brings in a fresh, independent critic every round. The critic never hears the target. It scores the work with a fixed rubric against fresh captures, including the hard states: everything switched on, the longest text, the phone width. Implementers fix the top defects and the critic comes back. The climb stops at the target, when the score plateaus, or when the budget runs out. The design decisions get written down so the next change keeps the direction.

### product-readme

READMEs that sell the product to the people who'll use it. Real screenshots with believable demo data, a hero in light and dark, claims backed by something in the repo, and the developer details moved to where developers look.

### web-quality

Lighthouse on the production build, a median of three runs per configuration, the pages that matter, SEO and GEO done properly, and a visual pass at phone, tablet and desktop widths. You get a before-and-after table and an honest note on where chasing the last point stopped being worth it.

### project-digest

The morning read: new issues and comments from real people (first-timers flagged), PRs that are ready, red or behind, and your PRs in other people's repos. If nothing needs you, it says so in one line. Read only, so it's safe to run on a schedule.

### tidy-repos

Branches whose PRs merged, worktrees that are clean and merged, stale refs: gone. Squash merges are detected through GitHub, so nothing is guessed from `git branch --merged`. Anything unmerged or with changes is listed for you, never deleted. It also never touches a worktree that an unsettled T3 thread still owns, or one holding ignored files like `.env`.

### verify

Green mocked tests aren't proof. verify picks the way to see the change working: the T3 preview browser for the web, the device tools for simulators, the built app for macOS, curl and logs for servers. It also opens the states that hide bugs, like everything switched on, the longest text and the phone width. It never kills the copy of the app you're using.

### pr-comments

Comments that sound like you on a good day: two or three sentences, the point first, friendly to people and no filler. Anything a person will read is shown to you as a draft first. Replies to review bots go out directly, with a note that an agent wrote them.
