---
name: web-quality
description: Measure and fix a website's quality. Covers Lighthouse scores (performance, accessibility, best practices, SEO), Core Web Vitals, SEO and GEO (structured data, llms.txt, sitemap, meta tags), and a visual pass on phone and desktop in light and dark mode. Use when the user asks for Lighthouse or Core Web Vitals scores, "perfect scores", SEO, GEO or LLM visibility, structured data, or a visual check of a site.
---

# Web quality

Measure first, fix by impact, then measure again.

## Measure

Test the production build, a preview deployment, or production, never the dev
server. Previews are usually `noindex`, so judge SEO on production. Note the
commit and the URL.

Run Lighthouse three times per page and configuration, and take the median:

```bash
npx lighthouse <url> --output=json --output-path=<file> --quiet --chrome-flags="--headless=new"
```

The default is mobile; add `--preset=desktop` for desktop. Test the key pages,
not only the home page. Read the failing audits, not just the scores. The
usual causes:
- images not served in the modern format
- render-blocking CSS and fonts
- long dependency chains
- the back/forward cache blocked
- layout shift
- missing labels and low contrast

## SEO and GEO

Check on production:
- title, description, canonical and Open Graph tags
- `robots.txt`, and a `sitemap.xml` with correct absolute URLs, image URLs
  included
- valid JSON-LD that fits the site, such as `Person`, `LocalBusiness`,
  `SoftwareApplication` or `FAQPage`
- an `llms.txt` with plain facts and links
- content that answers questions plainly

If a Search Console MCP is there, read from it; change things only when asked.

## Visual pass

In the T3 preview browser, check every page at 390, 768 and 1280 px
(`preview_resize`), in light and dark (`preview_set_appearance`). Scroll each
page fully and use the main interactions. Look for:
- overflow
- cut-off text
- spacing that's off on mobile
- a missing `cursor: pointer`
- small tap targets
- media that doesn't load

Close the tabs you opened.

## Fix and report

Fix the biggest wins first and re-measure the pages each fix affects. Weigh
the cost of each optimization: a 40 KB saving rarely justifies swapping out a
library the site relies on. Revert what didn't pay off, and say where you
stopped chasing points.

Report:
- a table per page and configuration with the four scores, LCP, CLS and
  INP/TBT, before and after
- the SEO and GEO checklist
- the visual fixes
- what's left

Land the fixes with `ship-it` if the user asks.
