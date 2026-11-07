---
name: verify
description: Prove that a change works by seeing it work, not by trusting mocked tests. Use the right tool per platform in T3 Code (preview browser for the web, device tools for simulators, the built app for macOS), cover the hard states, and report what is and isn't verified. Use when the user says "verify yourself", "check it in the preview browser", "test it in the simulator", and whenever another skill asks for proof inside T3 Code.
---

# Verify

Proof is something you observed yourself in this session: command output, a
reproduction that fails before the fix and passes after, a screenshot of the
real thing. Green mocked tests don't prove the user experience. If you can't
prove a change, say so instead of guessing.

## Pick the method

- **Code without a UI:**
  - run what CI runs
  - reproduce the bug, fix it, and run the same reproduction again
  - add one focused test that fails without the fix
- **Web:** run a dev server or a preview build, and use the T3 preview
  browser (outside T3, `playwright-cli`):
  - `preview_open` and `preview_navigate` to load the page
  - `preview_act` to click and type
  - `preview_snapshot` to look at it
  - `preview_resize` for 390, 768 and 1280 px
  - `preview_set_appearance` for light and dark

  Check the console for errors, and close the tabs you opened.
- **iOS or Android simulator:** `device_list`, then `device_open`. Run the
  command it returns for launches, taps, text and screenshots, and look with
  `device_screenshot`. Don't drive the device with `simctl` or `adb`; build
  and install with the project's commands.
- **A physical iPhone:** install with the project's command and check that it
  launches. The user tests the hardware features.
- **macOS apps:** build and launch your own copy, following the project's
  rules for copies the user is running. Then screenshot its window, and use
  computer use only as allowed below.
- **Servers:** start one, curl its endpoints, and read the logs.
- **Production:** load the live URL and look at the thing that changed, not
  just at the status code.

## Cover the hard states

Bugs hide in the states nobody opens:
- everything switched on
- the longest text
- the smallest and the largest window
- empty, loading and error states
- light and dark
- motion: typing, scrolling, animations

Measurements on shared hardware (GPU, Neural Engine) run one at a time, under
the lock in `fan-out`'s **Shared resources** rules.

## Respect the user's setup

- If the user says they'll test it, leave that part to them.
- Use computer use when the user asks for it or says they aren't using the
  machine. Then you may also restart your own builds.
- Never kill the user's running copy of an app or their dev server; stop only
  what you started.
- Leave a dev server running if the user wants to look at it.

## Report

- what you ran and what you saw
- where the screenshots are
- what is still unverified, and why
