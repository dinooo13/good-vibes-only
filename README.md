# Good Vibes Only ✌️

Claude Code plugins that give your agents good vibes. Small, focused skills that take care of the annoying parts of agent work, so your agents can stay on the task and you don't have to babysit them.

```
/plugin marketplace add dinooo13/good-vibes-only
/plugin install usage-limits@good-vibes-only
```

## The lineup

### usage-limits

Nothing kills the vibe like hitting your usage limit mid-refactor, with half the files renamed.

This skill keeps an eye on your 5-hour and 7-day usage windows while Claude works. When a limit gets close, Claude finishes the current step, commits, leaves itself a handoff note, and waits until the window resets. Then the same thread wakes up, reads the note, and carries on.

- `/usage-limits:usage-limits check` shows current usage.
- `/usage-limits:usage-limits watch 85` starts a background watcher that ends at 85% of the 5-hour window.
- `/usage-limits:usage-limits pause` wraps up now and waits for the reset.

Claude also loads the skill on its own before long jobs.

**Requirements:** `bash`, `curl`, `jq`, and a Claude Code login with a Pro or Max subscription.

**How it knows:** usage comes from Anthropic's OAuth usage endpoint, using the token Claude Code already stores (macOS keychain, or `~/.claude/.credentials.json` on Linux). The token goes to curl on stdin, never on a command line, and is never cached or printed.

The endpoint sometimes rate-limits requests. When that happens, every check on the machine backs off (1 minute, doubling up to 15). Meanwhile the skill asks [CodexBar](https://github.com/steipete/CodexBar) if it's installed. Otherwise it uses the last good result for up to 15 minutes, clearly marked as stale. CodexBar is optional.

**One catch:** the wait belongs to the Claude Code session. If you close the app or the thread, nothing resumes.
