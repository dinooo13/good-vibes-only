---
name: almost-ship-it
description: Everything ship-it does except the merge. Prove it, review it, open the PR and babysit it until the merge gate passes, then stop with the PR ready for the user to merge. Use when the user says "almost ship it", "ship it but don't merge", or "get it ready to merge".
---

# Almost ship it

Follow [ship-it](../ship-it/SKILL.md)'s steps 1 to 4 with merge permission off
(use `until: "checks"` on `watch_pull_request`), and never merge. Once the
merge gate passes, call `unwatch_pull_request` and report as ship-it does. Skip
steps 5 and 6.

End with one line: say "ship it" to merge.
