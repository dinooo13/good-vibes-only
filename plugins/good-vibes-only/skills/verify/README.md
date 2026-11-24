# verify

Proof you can see: preview browser, simulator, the real app, the hard states.

**Say:** "verify yourself"

Green mocked tests aren't proof. verify picks the way to see the change working: the T3 preview browser for the web (`playwright-cli` outside T3), the device tools for simulators, the built app for macOS, curl and logs for servers. It also opens the states that hide bugs, like everything switched on, the longest text, the phone width, and light and dark. It reads the repo's `## Verify` section first and uses its scripts before improvising. If there is none, it says so and suggests build-verification-environment. It never kills the copy of the app you're using, and it tells you what it couldn't verify.

---

Part of [Good Vibes Only](../../../../README.md). The instructions Claude follows are in [SKILL.md](SKILL.md).
