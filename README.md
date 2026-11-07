# Good Vibes Only ✌️

Claude Code plugins that give your agents good vibes. Useful skills that take care of the annoying parts of agent work, so your agents can stay on track and you don't have to babysit them.

```
/plugin marketplace add dinooo13/good-vibes-only
/plugin install good-vibes-only@good-vibes-only
```

The `good-vibes-only` plugin bundles the workflow skills below. They're bundled because they lean on each other: ship-it proves changes with verify and answers bots with pr-comments, and fan-out hands every PR to review-loop and ship-it. Claude picks them up from what you say, or you call them directly, for example `/good-vibes-only:ship-it`.

The workflow skills are made for [T3 Code](https://github.com/pingdotgg/t3code). They use its tools for threads, delegated agents, PR watching, the preview browser and scheduled tasks.

## The lineup

| Skill | Say | What happens |
| --- | --- | --- |
| [ship-it](#ship-it) | "ship it" | Verify, PR, babysit, rebase, merge, pull main, install or deploy, check live, clean up |
| [review-loop](#review-loop) | "review loop", "council" | A fresh Opus xhigh reviewer reviews; you fix; repeat until it approves |
| [fan-out](#fan-out) | "fan out issues 36–38" | One T3 thread per issue: plan, your go, implement, verify, review, ship |
| [handoff](#handoff) | "write a handoff" | A brief that lets a new thread carry on without your history |
| [hill-climb](#hill-climb) | "until the critic gives a 9" | Critic rounds with a fixed rubric until the score reaches the target |
| [product-readme](#product-readme) | "make the README sell it" | Hero, real screenshots, short install, details moved out |
| [web-quality](#web-quality) | "check the core web vitals" | Lighthouse, SEO and GEO, and a visual pass, before and after |
| [project-digest](#project-digest) | "what needs me?" | Who's waiting on you, what's broken, what's ready to merge |
| [tidy-repos](#tidy-repos) | "clean up branches" | Merged branches and clean worktrees go; stale work gets listed |
| [verify](#verify) | "verify yourself" | Proof you can see: preview browser, simulator, the real app, the hard states |
| [pr-comments](#pr-comments) | "draft a reply" | Short comments in your voice, drafts before people see them, a note on bot replies |

### ship-it

"Ship it" should mean shipped, not "PR opened, good luck". The skill proves the change before the PR, then babysits checks and review bots. It rebases when the branch falls behind and only merges once the gate is green. After the merge it pulls main, installs or deploys, and looks at the result live. Each project says how to install and deploy in a `## Ship` section of its `CLAUDE.md`. Without one, the skill proposes it.

### review-loop

A second opinion, as many times as it takes (three rounds by default). The reviewer, Opus at xhigh unless you name another, runs in its own thread with no history and labels each finding blocker, should or nit. You fix what's real, push back with evidence, and decline scope creep. Say "council" to get three providers at once. The verdicts per round end up in the PR description.

### fan-out

Hand it a handful of issues. It writes the missing "Done when" criteria, works out which issues depend on each other, and starts one T3 thread per issue in its own worktree. Each thread runs the whole flow: a Fable planner, a short summary for you, an Opus implementer, then verify, review-loop and ship-it on its own PR. You approve all the plans in one place, the coordinator. Threads take turns on shared resources like benchmarks, and a dependent issue starts only after the issue it needs has merged. With `--plan-only` it just posts plans on the issues, which makes a nice overnight job.

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
