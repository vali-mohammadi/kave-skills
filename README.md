# kave-skills

Agent skills that improve themselves. Inspired by [karpathy/autoresearch](https://github.com/karpathy/autoresearch).

## The idea

Give an agent a small set of real skills and let it experiment autonomously. It edits a skill file, scores the result, keeps or discards, and repeats. You wake up to a log of experiments and (hopefully) better skills.

**You only ever edit `program.md`.** The agent edits the skills.

## How it works

Three things matter:

- **`program.md`** — your research instructions. Steer the agent here. Set focus, constraints, and direction. The agent reads this and runs.
- **`skills/`** — the files the agent edits. Like `train.py` in autoresearch.
- **`results.tsv`** — untracked log of every experiment: what was tried, score before/after, keep or discard.

## Quick start

```bash
# Point your agent at this repo and say:
"Read program.md and let's kick off a new run."
```

The agent proposes a run tag (e.g. `jun21`), creates branch `autoresearch/jun21`, baselines the current skills, then loops forever improving them.

## Skills

| Skill | What it does |
|-------|-------------|
| `/graph-notation` | Turns a numbered notation plan into a Mermaid decision tree. Confirms before any agent fires. |
| `/grok-orchestrator` | Executes the confirmed plan by spawning headless `grok` CLI instances layer by layer. |
| `/client-project-kickoff` | Turns a signed scope of work into internal delivery artifacts — folder structure, redacted team briefs, an AI context file, a decision log, and a thinly seeded tracker. |

### client-project-kickoff

Ships three tools alongside `SKILL.md`:

- **`redaction-audit.sh`** — greps generated documents for fees, payment terms, contact details, and contract IDs. Prints an explicit `CLEAN`/`FAIL`, exits non-zero on findings. BSD-portable, so it works on stock macOS.
- **`ltr-runs.lua`** — pandoc filter that stops multi-word Latin runs reversing inside right-to-left text. Without it, `Hai Booca` renders as `Booca Hai` in a Persian PDF, while single words look perfect. No-ops on non-RTL documents.
- **`pdf-header.tex`** — shared LaTeX preamble: URL breaking, and suppressing hyphenated line breaks in Persian.

`MECHANICS.md` covers the RTL pipeline in full, including why verification must rasterize the PDF rather than read its text.

Works standalone. Pair it with a private org-context skill to override the generic defaults with house conventions.

## Notation quick-ref

| Symbol | Meaning | Example |
|--------|---------|---------|
| `@Ns` | timeout | `analyze @60s` |
| `!` | halt on fail | `deploy ! prod` |
| `~ condition` | loop until | `fix ~ pass` |
| `*N` | repeat N times | `draft *3` |
| `&` | parallel | `test & lint` |
| `\|` | branch | `refactor \| direct` |
| `> < =` | condition | `score > 7` |
| `>>` | merge results | `report >>` |

See [`skills/graph-notation/EXAMPLES.md`](skills/graph-notation/EXAMPLES.md) for 9 worked examples.

## Metric

Skill quality score (0–10). Five criteria, 2 points each:
1. Description has clear "Use when" triggers
2. SKILL.md has a concrete completion criterion
3. All operators / concepts covered by at least one example
4. SKILL.md under 100 lines
5. A cold agent reading only SKILL.md could execute it

## Branch naming

Each run gets its own branch: `autoresearch/<tag>` (e.g. `autoresearch/jun21`).
Results are logged to `results.tsv` (untracked — stays local).
