# Good Vibes Only

My Claude Code plugins, published as a plugin marketplace.

```
/plugin marketplace add dinooo13/good-vibes-only
/plugin install usage-limits@good-vibes-only
```

## Plugins

### usage-limits

Keeps long autonomous jobs from running into a subscription limit mid-step. The skill checks the 5-hour and 7-day usage windows, watches them in the background, and near a limit has Claude finish the current step, write a handoff note, and sleep until the window resets. The same thread then wakes up and continues.

- `/usage-limits:usage-limits check` shows current usage.
- `/usage-limits:usage-limits watch 85` starts a background watcher that ends at 85% of the 5-hour window.
- `/usage-limits:usage-limits pause` wraps up now and waits for the reset.

Claude also loads the skill on its own before long jobs.

Requirements: `bash`, `curl`, `jq`, and a Claude Code login with a Pro or Max subscription. Usage comes from Anthropic's OAuth usage endpoint with the token Claude Code already stores (macOS keychain, or `~/.claude/.credentials.json` on Linux). The token is passed to curl on stdin, never on a command line, and is not cached or printed. The endpoint rate-limits, so after a failed request all checks on the machine back off (1 minute, doubling up to 15) and fall back to [CodexBar](https://github.com/steipete/CodexBar) if it is installed, otherwise to the last good result for up to 15 minutes, marked stale. CodexBar is optional.

Background waits live and die with the Claude Code session: if the app or thread closes, nothing resumes.

## Development

```bash
tests/usage-limits.sh                         # offline tests with a faked keychain, curl and codexbar
claude plugin validate --strict .             # marketplace manifest
claude plugin validate --strict plugins/usage-limits
claude --plugin-dir plugins/usage-limits      # try a plugin without installing it
```
