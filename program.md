# kave-skills autoresearch

You are an autonomous agent improving agent skills in this repo.
The human edits this file to steer direction. You edit the skills and log results.

## Setup

To start a new run, work with the user to:

1. **Agree on a run tag**: propose a tag based on today's date (e.g. `jun21`). Branch `autoresearch/<tag>` must not exist — fresh run only.
2. **Create the branch**: `git checkout -b autoresearch/<tag>` from current main.
3. **Read all in-scope files**:
   - `program.md` — this file. Your instructions.
   - `skills/communication/graph-notation/SKILL.md` — skill under improvement
   - `skills/communication/graph-notation/NOTATION.md` — operator reference
   - `skills/communication/graph-notation/EXAMPLES.md` — worked examples
   - `skills/engineering/grok-orchestrator/SKILL.md` — skill under improvement
   - `skills/engineering/grok-orchestrator/EXECUTION.md` — execution reference
4. **Initialize results.tsv**: create with header row only. Baseline recorded after first eval.
5. **Confirm setup and go.**

## What you CAN modify
- Any `SKILL.md`, `NOTATION.md`, `EXAMPLES.md`, `EXECUTION.md` file
- Add new files inside a skill folder
- Add entirely new skills under `skills/`

## What you CANNOT modify
- `program.md` — human edits this only
- `.claude-plugin/plugin.json` — only add entries if you add a whole new skill
- `package.json`, `.gitignore`

## The metric: skill quality score (0–10, higher is better)

Run this self-evaluation after every change. Score each skill you modified:

| Criterion | Points |
|-----------|--------|
| Description has clear "Use when" triggers | 0–2 |
| SKILL.md has a concrete completion criterion | 0–2 |
| All operators / concepts have at least one example | 0–2 |
| SKILL.md is under 100 lines (concision) | 0–2 |
| A cold agent reading only SKILL.md could execute the skill | 0–2 |

Score = sum across all 5 criteria for the modified skill.
Record the score as the metric in `results.tsv`.

**Baseline first**: your very first run must evaluate the skills as-is, without changes.

## Output format

After each eval, self-report:

```
---
skill:            graph-notation
score:            7/10
criteria_hits:    triggers✓ completion✓ coverage✓ concision✗ cold-read✗
git_commit:       abc1234
```

## Logging

Log every experiment to `results.tsv` (tab-separated, NOT comma-separated):

```
commit	skill	score	status	description
```

- **commit**: 7-char hash
- **skill**: which skill was modified (or `both`)
- **score**: N/10
- **status**: `keep`, `discard`, or `revert`
- **description**: one-line summary of what was tried

Example:
```
commit	skill	score	status	description
a1b2c3d	—	7/10	keep	baseline
b2c3d4e	graph-notation	8/10	keep	tighten description triggers, remove no-ops
c3d4e5f	graph-notation	7/10	discard	added verbose operator table (bloat, no gain)
d4e5f6g	grok-orchestrator	9/10	keep	cold-read fix: added missing entry-point explanation
```

Do NOT commit `results.tsv` — leave it untracked.

## The experiment loop

LOOP FOREVER:

1. Read current skill files and current score from `results.tsv`
2. Form one hypothesis: "If I change X, the score will improve because Y"
3. Edit the relevant skill file(s)
4. Re-evaluate: run the 5-criterion scoring rubric
5. git commit
6. Log to `results.tsv`
7. If score improved → keep commit, advance
8. If score equal or worse → `git reset --hard HEAD~1`, log as `discard`
9. Repeat

**Simplicity wins.** A +0 score improvement from deleting 10 lines? Keep. A +1 from adding 30 lines of marginal examples? Probably not worth it.

**NEVER STOP.** Do not ask "should I keep going?" The human may be away. Run until interrupted.

**Idea generation:** if stuck, try:
- Prune no-ops (lines the agent already obeys by default)
- Tighten the description to reduce context load
- Add a missing operator example
- Split a step that causes premature completion
- Add a leading word that anchors a whole behaviour in one token
- Rewrite for a cold reader with no prior context

## Current research direction

> Improve `graph-notation` first. Priority: cold-read clarity and operator coverage.
> Then improve `grok-orchestrator`: the verifier prompt templates need to be battle-tested.

*(Human: edit this section to steer the agent's focus.)*
