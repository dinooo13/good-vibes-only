#!/usr/bin/env python3
"""Writes assets/fan-out-light.svg and assets/fan-out-dark.svg.

Usage: python3 assets/src/fan-out-diagram.py
"""
from pathlib import Path

THEMES = {
    "light": dict(text="#1f2328", muted="#59636e", line="#afb8c1", pill="#f6f8fa", pill_stroke="#d0d7de",
                  start="#ddf4ff", start_stroke="#54aeff", start_text="#0550ae",
                  go="#fff8c5", go_stroke="#d4a72c", go_text="#7d4e00",
                  done="#dafbe1", done_stroke="#4ac26b", done_text="#1a7f37",
                  band="#fbefff", band_stroke="#c297ff", band_text="#8250df", inner="#ffffff"),
    "dark": dict(text="#e6edf3", muted="#9198a1", line="#3d444d", pill="#151b23", pill_stroke="#3d444d",
                 start="#0c2d4a", start_stroke="#1f6feb", start_text="#79c0ff",
                 go="#2e2500", go_stroke="#9e6a03", go_text="#f2cc60",
                 done="#0f2a18", done_stroke="#2ea043", done_text="#3fb950",
                 band="#1c1433", band_stroke="#6e40c9", band_text="#d2a8ff", inner="#0d1117"),
}

W, H = 96, 40                       # pill size
ROWS = [("#36", 64), ("#37", 136), ("#38", 208)]  # label, pill top
BEFORE = [("plan", 240), ("your go", 344), ("implement", 448)]
INSIDE = [("verify", 576), ("review-loop", 680), ("PR · merge", 784)]
BAND = (562, 24, 332, 236)          # x, y, width, height of the ship-it band
DONE_X = 908
WIDTH, HEIGHT = 1016, 316


def svg(c):
    out = [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {WIDTH} {HEIGHT}" width="{WIDTH}" height="{HEIGHT}" role="img" '
           'aria-label="fan-out: one request becomes three issue threads. Each runs plan, your go and implement, then ship-it, '
           'which runs verify, review-loop and the PR until it merges">',
           f"<style>text{{font-family:-apple-system, BlinkMacSystemFont, 'Segoe UI', 'Noto Sans', Helvetica, Arial, sans-serif;"
           f"font-size:15px;fill:{c['text']}}} .m{{font-family:ui-monospace, SFMono-Regular, 'SF Mono', Menlo, Consolas, monospace;font-size:14px}}</style>"]
    bx, by, bw, bh = BAND
    out.append(f'<rect x="{bx}" y="{by}" width="{bw}" height="{bh}" rx="16" fill="{c["band"]}" stroke="{c["band_stroke"]}" stroke-width="1.5"/>')
    out.append(f'<text x="{bx + bw / 2}" y="{by + 26}" text-anchor="middle" class="m" style="fill:{c["band_text"]};font-weight:700">ship-it</text>')
    cy0 = ROWS[1][1] + H / 2
    out.append(f'<rect x="12" y="{cy0 - 38}" width="168" height="76" rx="12" fill="{c["start"]}" stroke="{c["start_stroke"]}" stroke-width="1.5"/>')
    out.append(f'<text x="96" y="{cy0 - 7}" text-anchor="middle" class="m" style="fill:{c["start_text"]}">"fan out</text>')
    out.append(f'<text x="96" y="{cy0 + 15}" text-anchor="middle" class="m" style="fill:{c["start_text"]}">issues 36–38"</text>')

    def pill(label, x, y, fill, stroke, color, weight=400):
        out.append(f'<rect x="{x}" y="{y}" width="{W}" height="{H}" rx="20" fill="{fill}" stroke="{stroke}" stroke-width="1.5"/>')
        out.append(f'<text x="{x + W / 2}" y="{y + 25}" text-anchor="middle" style="fill:{color};font-weight:{weight}">{label}</text>')

    def link(x1, x2, y):
        out.append(f'<line x1="{x1}" y1="{y}" x2="{x2}" y2="{y}" stroke="{c["line"]}" stroke-width="1.5"/>')

    for label, y in ROWS:
        cy = y + H / 2
        out.append(f'<path d="M180 {cy0} C 204 {cy0}, 188 {cy}, 198 {cy}" fill="none" stroke="{c["line"]}" stroke-width="1.5"/>')
        out.append(f'<text x="205" y="{cy + 5}" style="fill:{c["muted"]};font-size:14px">{label}</text>')
        steps = [(n, x, c["pill"], c["pill_stroke"], c["text"], 400) for n, x in BEFORE]
        steps[1] = ("your go", BEFORE[1][1], c["go"], c["go_stroke"], c["go_text"], 600)
        steps += [(n, x, c["inner"], c["pill_stroke"], c["text"], 400) for n, x in INSIDE]
        steps.append(("merged ✓", DONE_X, c["done"], c["done_stroke"], c["done_text"], 600))
        for (_, x, *_), (_, nx, *_) in zip(steps, steps[1:]):
            link(x + W, nx, cy)
        for s in steps:
            pill(*s[:1], s[1], y, *s[2:])

    go_x = BEFORE[1][1] + W / 2
    base = ROWS[-1][1] + H
    out.append(f'<path d="M{go_x} {base + 4} L{go_x} {base + 24}" stroke="{c["go_stroke"]}" stroke-width="1.5" stroke-dasharray="3 3"/>')
    out.append(f'<text x="{go_x}" y="{base + 48}" text-anchor="middle" style="fill:{c["muted"]};font-size:14px">all three plans, approved in one place</text>')
    out.append(f'<text x="{bx + bw / 2}" y="{base + 48}" text-anchor="middle" style="fill:{c["muted"]};font-size:14px">proof, review and PR, one skill</text>')
    out.append(f'<text x="{DONE_X + W / 2}" y="{base + 48}" text-anchor="middle" style="fill:{c["muted"]};font-size:14px">one PR each</text>')
    out.append("</svg>\n")
    return "\n".join(out)


root = Path(__file__).resolve().parents[2]
for name, colors in THEMES.items():
    (root / "assets" / f"fan-out-{name}.svg").write_text(svg(colors), encoding="utf-8")
    print(f"assets/fan-out-{name}.svg")
