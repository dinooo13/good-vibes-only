---
name: product-readme
description: Write or rework a product-focused README that sells the project to its users. It gets a one-line value, a hero image or GIF, real screenshots with believable demo data, a short install with details moved to sub pages, and the repo description and topics. Use when the user asks for "a product focused README", "make the README sell it", "add screenshots" or "add a hero GIF", or says the README is too long or too technical.
---

# Product README

The README is the landing page, and a reader decides in ten seconds. Sell the
product to its users. Developer details go further down or into other files.

Read the code, the docs, the site and the releases. Work out who the reader
is; ask if it's unclear. Collect the claims you can back up: benchmarks,
privacy, price, platforms. Never invent a number.

**Default order:**
1. the name, a one-line value statement, and a few badges
2. a hero image or GIF of real use, in light and dark with `<picture>`
3. 3 to 5 benefits, each backed by a fact
4. screenshots with short captions
5. the shortest install path, with the long version in `INSTALL.md`
6. how it works in a few lines, with links to the docs
7. an FAQ, the license and credits

Move the architecture, development setup and contribution rules to `docs/`
and `CONTRIBUTING.md`.

When reworking, keep what works and change about as much as the user asked
for. A README that suddenly feels unfamiliar is a failed rework.

**Screenshots and GIFs:** capture the real app with believable demo data,
local to the audience and never "Test 1". Use the T3 preview browser for the
web (`preview_resize`, `preview_set_appearance`), the T3 device tools for
simulators, and the built app for macOS. Convert GIFs with `ffmpeg`, keep
them under about 5 MB, and show a sped-up typical day rather than a feature
tour.

**Repo metadata:** draft the description, topics and homepage, and show them
with the README draft. Run `gh repo edit` only after the user's OK, because
it's public at once.

Check the rendered README on the branch's GitHub page, in light and dark mode.
Then land it with `ship-it`, or as the user asks.
