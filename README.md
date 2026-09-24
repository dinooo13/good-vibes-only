# Good Vibes Only ✌️

Claude Code plugins that give your agents good vibes. Useful skills that take care of the annoying parts of agent work, so your agents can stay on track and you don't have to babysit them.

```
/plugin marketplace add dinooo13/good-vibes-only
/plugin install usage-limits@good-vibes-only
```

## The lineup

### usage-limits

Nothing kills the vibe like hitting your usage limit mid-run, with half the work completed.

This skill keeps an eye on your 5-hour and 7-day usage windows while Claude works. When a limit gets close, Claude finishes the current step, commits, leaves itself a handoff note, and waits until the window resets. Then the same thread wakes up, reads the note, and carries on.

### How the waking up works:
Claude starts a background script that sleeps until the window resets, then exits. Claude Code notifies the same thread, and Claude picks up where it left off. The wait costs no tokens.

Just tell Claude to continue once your limit resets to trigger.
Claude also loads the skill on its own before long jobs.

### Requirements:
`bash`, `curl`, `jq`, and a Claude Code login with a Pro or Max subscription.

### How it knows:
Usage comes from Anthropic's OAuth usage endpoint, using the token Claude Code already stores (macOS keychain, or `~/.claude/.credentials.json` on Linux). The token goes to curl on stdin, never on a command line, and is never cached or printed.

The endpoint sometimes rate-limits requests. When that happens, every check on the machine backs off (1 minute, doubling up to 15). Meanwhile the skill asks [CodexBar](https://github.com/steipete/CodexBar) if it's installed. Otherwise it uses the last good result for up to 15 minutes, clearly marked as stale. CodexBar is optional.

### One catch:
The wait belongs to the Claude Code session. If you close the cli or the app, nothing resumes.
