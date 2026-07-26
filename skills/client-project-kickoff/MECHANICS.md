# Brief Generation Mechanics

## Markdown to PDF

```bash
pandoc "Brief (EN).md" -o "Brief (EN).pdf" --pdf-engine=xelatex -V geometry:margin=1in
```

Requires `pandoc`, a TeX distribution providing `xelatex`, and `poppler` for the verification step (`brew install pandoc poppler`).

## Right-to-left languages (Persian, Arabic, Hebrew)

Set in the markdown frontmatter:

```yaml
lang: fa
dir: rtl
mainfont: "Tahoma"
```

RTL layout comes from `polyglossia`/`bidi`, not from xelatex alone. Confirm before a first run on an unfamiliar machine:

```bash
kpsewhich polyglossia.sty
```

### Font choice is not cosmetic

`Geeza Pro` renders Persian but **has no Latin glyphs**. Every embedded English term — product names, tool names, brand names — silently disappears, emitting one `Missing character` warning per letter. `Tahoma` ships with macOS at `/System/Library/Fonts/Supplemental/` and covers both scripts. Use it as the default.

## Verification: rasterize, never extract

**Extracted text from an RTL PDF is not evidence.** `pdftotext`, and any tool that reads the PDF as text, returns glyphs in *visual* order with embedded bidi control characters. Correct output looks scrambled and mirrored — `(Axtiq)` comes back as `(Axtiq(`, parentheses apparently reversed, when the rendered page is perfectly fine.

Diagnosing from extracted text produces false alarms, and the "fix" — rewriting Persian copy to avoid brackets — permanently degrades the document to dodge a bug that was never there.

Render to an image and look at it:

```bash
pdftoppm -png -r 150 "Brief (FA).pdf" page
```

Then view `page-1.png`. This is the only reliable check. It is also the only way to catch wrap-dependent issues, which cannot be detected in the source at all.

### What actually goes wrong

Verified working on pandoc 3.10 / TeX Live 2026 / macOS: parentheses, guillemets, mixed Latin-in-Persian, Persian numerals, bulleted lists. Do not preemptively rewrite copy to avoid these.

Real failure modes worth checking on the rendered image:

- **Missing glyphs** — wrong font. Produces `Missing character` warnings at build time, so watch the pandoc output.
- **Whole document rendering left-to-right** — `dir: rtl` not applied, or `polyglossia` absent.
- **Punctuation landing on the wrong side of a line break** — cosmetic, wrap-dependent, visible only in the image.
