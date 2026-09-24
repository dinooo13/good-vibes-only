# Good Vibes Only ✌️

A Claude Code plugin marketplace with a strict door policy. Plugins get in if they make agents calmer, tidier, or less likely to faceplant halfway through a job. Bad vibes get turned away at the door.

```
/plugin marketplace add dinooo13/good-vibes-only
/plugin install usage-limits@good-vibes-only
```

## The lineup

### usage-limits

Nothing kills the vibe like hitting your usage limit mid-refactor, with half the files renamed and no idea what the plan was.

This skill keeps an eye on your 5-hour and 7-day usage windows while Claude works. When a limit gets close, Claude finishes the current step, commits, leaves itself a handoff note, and takes a nap until the window resets. Then the same thread wakes up, reads the note, and carries on like nothing happened.

- `/usage-limits:usage-limits check` shows how much vibe is left.
- `/usage-limits:usage-limits watch 85` starts a background watcher that ends at 85% of the 5-hour window.
- `/usage-limits:usage-limits pause` wraps up now and waits for the reset.

Claude also loads the skill on its own before long jobs.

**Requirements:** `bash`, `curl`, `jq`, and a Claude Code login with a Pro or Max subscription.

**How it knows:** usage comes from Anthropic's OAuth usage endpoint, using the token Claude Code already stores (macOS keychain, or `~/.claude/.credentials.json` on Linux). The token goes to curl on stdin, never on a command line, and is never cached or printed.

The endpoint can get grumpy and rate-limit you. When that happens, every check on the machine backs off (1 minute, doubling up to 15). Meanwhile the skill asks [CodexBar](https://github.com/steipete/CodexBar) if it's installed. Otherwise it uses the last good result for up to 15 minutes, clearly marked as stale. CodexBar is optional.

**One catch:** the nap belongs to the Claude Code session. Close the app or the thread and nobody wakes up.
