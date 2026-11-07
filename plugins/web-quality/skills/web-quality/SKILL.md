---
name: web-quality
description: Measure and fix a website's quality. Covers Lighthouse scores (performance, accessibility, best practices, SEO), Core Web Vitals, SEO and GEO (structured data, llms.txt, sitemap, meta tags), and a visual pass on desktop and mobile in light and dark mode. Use when the user asks for Lighthouse or Core Web Vitals scores, "perfect scores", SEO, GEO or LLM visibility, structured data, or a visual check of a site before or after a launch.
---

# Web quality

Measure first, fix by impact, measure again. Report the scores before and
after.

## 1. Test the right build

- **Measure the production build**, not the dev server: a static export, a
  preview deployment, or production itself. Dev servers skew every number.
- **Ignore noindex hits on preview deployments.** Previews are usually
  `noindex`, so SEO scores there aren't comparable. Score SEO on production,
  or ignore that one finding on previews.
- Note the commit and the URL you tested.

## 2. Lighthouse

- Run the Lighthouse CLI against the URL, for mobile (the default) and desktop:
  - `npx lighthouse <url> --output=json --output-path=<file> --quiet --chrome-flags="--headless=new"`
  - add `--preset=desktop` for the desktop run
- Run each page and configuration three times and take the median; single
  runs are noisy. After a fix, re-run only the pages it affects.
- Test the key pages, not only the home page: a detail page, a long content
  page, and legal pages.
- Look at the failing audits, not only the scores. The usual suspects:
  - images without modern formats, sizes or lazy loading (check that the
    `webp` or `avif` really is served)
  - render-blocking CSS and fonts
  - long network dependency chains
  - back/forward cache blocked
  - layout shift from images or fonts without dimensions
  - missing labels and low contrast

## 3. SEO and GEO

Check on production:
- `<title>`, meta description, canonical, Open Graph and Twitter tags
- `robots.txt`, and `sitemap.xml` with correct absolute URLs (including image
  URLs)
- structured data (JSON-LD) that fits the site: `Person`, `Organization`,
  `LocalBusiness`, `SoftwareApplication`, `Product`, `FAQPage`. Validate it.
- `llms.txt`: a short, factual summary of the site and links to the key pages
- content that answers questions plainly. Generative engines quote clear facts,
  not slogans.

If a Search Console MCP is available, use it read-only (sitemaps, indexing,
queries). Submit or change anything there only when the user asks.

## 4. Visual pass

Use the T3 preview browser:
- widths of 390 px (phone), 768 px (tablet) and 1280 px or more (desktop),
  with `preview_resize`
- light and dark mode, with `preview_set_appearance`
- every page, scrolled fully, plus the main interactions: menus, forms,
  maps, video

Look for:
- overflow and horizontal scrolling
- text or breadcrumbs that get cut off
- spacing that is off on mobile
- clickable elements without `cursor: pointer`
- tap targets that are too small
- low contrast after colour changes
- media that doesn't load or loop as intended
- anything that works in one browser engine but not another

Fix what you find, then look again. Close the preview tabs you opened.

## 5. Fix by impact, weigh the cost

- Fix the biggest wins first, and re-measure after each group of fixes.
- Weigh the cost of each optimization: saving 40 KB by replacing a library the
  site relies on is rarely worth it. State the trade-off; if a change didn't
  pay off, revert it.
- Don't chase 100 when the last points need hacks that hurt maintainability.
  Say where you stopped and why.

## 6. Report

- A table: page and configuration; performance, accessibility, best
  practices and SEO; LCP, CLS and INP or TBT; before and after.
- The SEO and GEO checklist, with each item passed or fixed.
- The visual issues you found and fixed.
- What is left, with the trade-offs.

If the user wants it landed, continue with `ship-it`.
