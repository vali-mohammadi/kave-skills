# Brief Generation Mechanics

## Markdown to PDF

```bash
pandoc "Brief (EN).md" -o "Brief (EN).pdf" \
  --pdf-engine=xelatex \
  --lua-filter=ltr-runs.lua \
  -H pdf-header.tex \
  -V geometry:margin=1in
```

Use the **same command for every language**. `ltr-runs.lua` inspects the document's `dir` and no-ops on anything that is not RTL, so one invocation is correct for both halves of a bilingual pair.

Requires `pandoc`, a TeX distribution providing `xelatex`, and `poppler` for verification (`brew install pandoc poppler`).

## Right-to-left languages (Persian, Arabic, Hebrew)

Frontmatter:

```yaml
lang: fa
dir: rtl
mainfont: "Tahoma"
```

### Multi-word Latin runs reverse — the trap that hides

Inside an RTL paragraph, xelatex places each Latin **word** independently in the right-to-left flow. A single Latin word is fine. Two or more come out backwards:

- `(Hai Booca)` renders as `(Booca Hai)`
- `(Story Interaction)` renders as `(Interaction Story)`
- `Purple Berry Studio` renders as `Studio Berry Purple`

Because `Figma`, `WhatsApp`, and `CAT` all render perfectly, the document looks correct at a glance. What breaks is precisely the multi-word case — which is to say, **client and product names**. This shipped undetected in real client briefs.

Cause: pandoc's LaTeX template loads **babel**, not polyglossia, and selects `bidi=basic` (the real Unicode bidi algorithm) only under LuaTeX. Under xelatex it falls back to `bidi=default`, which positions each run independently. Checking for `polyglossia.sty` tells you nothing — pandoc is not using it.

**Fix:** `ltr-runs.lua` wraps each maximal Latin run in babel's `\babelsublr{}`, so the run lays out as one left-to-right span. It also handles code spans, and Latin fused directly to Persian punctuation (`Studio،`), which would otherwise break the run.

Two constraints the filter cannot work around:

- **`\babelsublr` exists only when an RTL language is loaded.** Applying the filter to an English document produces `Undefined control sequence` and no PDF. The filter guards on `dir` for exactly this reason — do not remove that guard.
- **Metadata is not processed.** `title:` is expanded by hyperref before babel's RTL support loads, and `mainfont:` is consumed as a raw LaTeX argument. Give an RTL document a multi-word Latin title as a body `#` heading, not YAML `title:`.

`--pdf-engine=lualatex` fixes the underlying bug natively with no filter, but needs `lualatex-math`, which BasicTeX does not ship.

### Font choice is not cosmetic

`Geeza Pro` renders Persian but **has no Latin glyphs**. Every embedded English term silently disappears, emitting one `Missing character` warning per letter. `Tahoma` ships with macOS at `/System/Library/Fonts/Supplemental/` and covers both scripts. Use it.

### The shared preamble

`pdf-header.tex` fixes two things that only appear in generated documents:

- **Long URLs overflow the right margin** in RTL. `\UrlBreaks` is widened to every letter and digit, deferred to `\AtBeginDocument` because pandoc injects header material before `hyperref` loads.
- **Persian breaks at a ZWNJ with an inserted hyphen.** Hyphenated breaks are suppressed and TeX given slack to justify without them.

Harmless for English, so apply it to both.

## Verification: rasterize, then actually read it

```bash
pdftoppm -png -r 150 "Brief (FA).pdf" page
```

**Extracted text from an RTL PDF is not evidence.** `pdftotext` and plain file reads return glyphs in visual order with bidi control characters — correct output looks scrambled, and broken output can look fine. Only the rendered image tells you anything.

Then read the image properly. Checking that brackets look right is not enough: **verify the word order of every multi-word Latin run**, and compare against the markdown source. A run reads correctly only if its words appear in source order.

### Checklist for the rendered page

- Multi-word Latin runs in source order — client names, product names, feature names
- No missing glyphs (these also produce build-time `Missing character` warnings)
- Document flows right-to-left, not left-to-right
- URLs inside the margin
- Punctuation on the expected side of a line break
