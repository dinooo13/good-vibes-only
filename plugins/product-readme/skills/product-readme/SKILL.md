---
name: product-readme
description: Write or rework a product-focused README that sells the project to its users. It gets a clear one-line value, a hero image or GIF, real screenshots with believable demo data, a short install section, with the details moved into sub pages, and the repo's description, topics and homepage. Use when the user asks for "a product focused README", "make the README sell it", "add screenshots" or "add a hero GIF", or says the README is too long or too technical.
---

# Product README

A README is the project's landing page. A reader decides in 10 seconds
whether it is for them. Sell the product to its users, and move the developer
details further down or into other files.

## 1. Understand the product

- **Read** the code, the existing README, the docs, the site and the release
  notes.
- **Who is it for?** The reader is often not a developer. Ask the user if it
  is unclear.
- **What can you claim?** Find the facts that sell it, with sources: benchmark
  results, privacy properties, price ("free"), supported platforms. Never
  invent a number. Every claim must point to something in the repo.

## 2. Structure

Use this order unless the project needs another:

1. **Name, a one-line value statement, and badges**: release, platform,
   license. Keep the badges few.
2. **Hero image or GIF** showing the product in use. Provide light and dark
   versions with `<picture>` and `prefers-color-scheme` when the UI has both.
3. **3 to 5 benefits** in plain words, each backed by a fact.
4. **Screenshots** of the main screens, with a short caption each.
5. **Install**: the shortest path (a download link, `brew install`, one
   command). Longer steps go to `INSTALL.md`.
6. **How it works**, in a few lines, plus links to the docs.
7. **FAQ** (optional), license and credits.

Move architecture, development setup and contribution rules to `docs/`,
`CONTRIBUTING.md` and the like, and link to them.

When reworking an existing README, keep what works. Change about as much as
the user asked for, not everything. A README that is suddenly unfamiliar is a
failed rework.

## 3. Screenshots and GIFs

- **Capture the real app** with believable demo data. Make it local to the
  audience (German names and places for a German audience) and make it look
  used, never "Lorem" or "Test 1".
- **Choose the capture tool:**
  - web: the T3 preview browser (`preview_resize` for desktop and phone widths,
    `preview_set_appearance` for light and dark)
  - iOS and Android: the T3 device tools on a simulator
  - macOS: run the app and capture its window
- **GIFs and videos:** record a short, realistic workflow, speed it up, and
  convert with `ffmpeg`, keeping the file small (usually under 5 MB).
  Product-focused means a typical day of use, not a feature tour.
- Store images in `docs/images/` or `.github/`, with descriptive names and
  alt text.

## 4. Repository metadata

Set the description, topics and homepage with
`gh repo edit --description … --add-topic … --homepage …`. Write the
description for search: what it is, for whom, and the key property.

## 5. Check and land

- Look at the rendered README on GitHub, on the branch (`.../blob/<branch>/README.md`).
  Check images in light and dark mode, and the relative links. GitHub caches
  the repo's front page, so check the branch view.
- Hand it to the user to read. Then open the PR with the `ship-it` skill, or
  as the user asked.
