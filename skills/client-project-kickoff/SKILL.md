---
name: client-project-kickoff
description: Use when starting a new client engagement from a signed scope of work and distributing it to internal delivery teams. Triggers on "kick off this project", "brief my team on this client work", "set up this project for my teams", or a freshly signed SOW/contract that internal teams need to act on.
metadata:
  author: kave
  version: "1.0.0"
---

# Client Project Kickoff

Turns a signed client contract into internal delivery artifacts: a shared-drive folder, redacted team-facing briefs, and seeded tracker projects.

**Core principle:** internal teams get the *working scope*, never the *commercial terms*. What the deal was worth is never their input.

**If an org-context skill is installed** (house terminology, people roster, document templates), read it first — its conventions override the generic defaults here.

## Stage 1 — Interview first

Produce nothing until these are answered. Ask one at a time, with a recommended answer where the question is a preference rather than a fact.

### Hard gates — always ask, in this order

0. **Get the contract.** The triggering request usually describes the engagement without attaching it. Ask for the document and read it. Never build a briefing from a verbal summary.
1. **Is this the current signed version?** Ask explicitly whether a later or superseding document exists. Do not proceed while currency is unconfirmed — a superseded SOW can differ in deliverables, phases, and price all at once.
2. **Which drive account?** Enumerate, don't guess: `ls ~/Library/CloudStorage/` (macOS + Google Drive Desktop). Ask whether the destination is the personal `My Drive` or a Shared drive.
3. **Which tracker, and is it connected?** Confirm the MCP server is authenticated *now*, before any artifact exists — an auth failure discovered at Stage 3 leaves a half-finished kickoff. Then enumerate teams (`list_teams`) rather than assuming.
4. **Confidentiality boundary** — state the default list below, ask what to add or remove.
5. **Brief languages** — offer the languages the delivery teams actually read; a single-language team makes a second pass pure waste. For a Persian-speaking studio, English + Persian is the usual pair. Ask per team, not per project.
6. **What is locked vs still open?** Never present unconfirmed scope as decided.
7. **Which teams, and who leads each?** Get real names, then resolve them to tracker accounts (`list_users`) before Stage 3.

### Then grill openly

The gates cover what is always true. Project-specific realities surface only through conversation. Interview relentlessly — one question at a time, each with a recommendation.

**Stop when you can state each of these in one sentence, and the user confirms:** the sequencing between teams, what the client's own people are handling, the fallback when they cannot, and who the finished work is ultimately *for*.

**When the contract and the client's stated wishes conflict, the signed contract governs.** Say so plainly, and record the wish as separately-scoped work rather than absorbing it.

## Default redaction list

**Strip:** fees and amounts · payment terms and schedule · engagement and document IDs · client legal name and personal contact details · agency registered address · commercial terms (revision allowances, hourly rates, support entitlements)

**Keep:** functional scope · timeline · deliverable format and hard limits · exclusions and out-of-scope items · asset links · process and communication channels

Teams need the boundaries as much as the work — keep the exclusions in.

## Stage 2 — Drive folder and briefs

```
<Account>/My Drive/Projects/<Client> — <Project>/
  CONTEXT.md                ← working context for the team's AI sessions
  DECISIONS.md              ← why the scope looks like this
  01 <Team> Brief/          ← one numbered folder per team, ordered by when they start
  02 <Team> Brief/
  03 Source Assets/         ← always last
```

`<Account>` is the literal mount directory (e.g. `GoogleDrive-you@company.com`); the separator in the project name is an em dash. Files: `<Doc> (EN).md` with `<Doc> (EN).pdf` beside it, one pair per language.

Write through the Drive Desktop mount as ordinary files; it syncs on its own. A native Google Doc would require the Drive API instead.

- **Writing files does not grant anyone access.** The mount is yours. Tell the user that sharing the folder with each team is a manual step you cannot do from here.
- **Never copy the client's own asset libraries in.** Link them from `03 Source Assets/`, noting they may go stale and should be snapshotted once the work locks.
- **Keep the contract out entirely** when the folder is meant to be shareable. Do not nest a confidential subfolder inside a folder whose purpose is sharing.
- See MECHANICS.md before generating PDFs — right-to-left output has a specific verification trap.

### REQUIRED sections — active brief

For the team whose phase is starting now:

- Overview
- **What's locked** — confirmed scope only
- **What's not yet locked** — named as open, with who resolves it and when
- **Open questions for the client** — flagged, never guessed at internally
- Reference material, explicitly marked context-only where it exceeds current scope
- Assets, timeline

### REQUIRED sections — downstream heads-up

A team whose phase begins only *after* another team finishes gets a **heads-up doc instead** — not the section list above, and named `Heads-up (EN).md` rather than `Brief`:

- Purpose line stating plainly that this is context, not a production brief
- Overview
- Pipeline and sequencing — what must finish before they start
- **What we know**
- **What we don't know yet**
- Open questions for the client
- Assets

### The context file

`CONTEXT.md` at the folder root — what a team member pastes or uploads to start an AI session about this engagement. Not a brief: a brief says what to build, this says who you are, what the constraints are, and how to behave.

**Treat it as leaving the building.** Used as intended, it goes straight into a third-party LLM. Apply the same redaction as the briefs; if a line would be awkward in the client's inbox, it does not belong here.

Compose it from three sources — house context from the org-context skill if installed, people from the tracker (never from memory), and this engagement from the interview. Include:

- Who the studio is, and who this project is for
- Teams involved and what each owns
- What is locked, what is open, and open questions for the client
- Hard limits and explicit exclusions
- Tools in use on this engagement
- **Behavioural guidance** — say when something is out of scope rather than designing it anyway; never present an open question as settled; flag gaps rather than inventing
- **Output conventions**, so the same document type comes out the same shape regardless of who asked

Stamp it with a snapshot date and name the authoritative sources, so a stale copy cannot quietly masquerade as current. Ship it in the same languages as the briefs.

### The decision log

`DECISIONS.md` at the folder root. The interview produces a dozen non-obvious calls — why a flow was cut, why two tracker containers instead of one, why assets are linked rather than copied, why the contract overrode what the client asked for. Without a record, that reasoning exists only in the conversation that produced it, and the first person to ask "why wasn't the dashboard scoped?" gets no answer.

Write it **during** the interview, not afterwards from memory. One row per decision:

```md
# <Client> — <Project> · Decisions

| Date | Decision | Why | Decided by |
|---|---|---|---|
| <date> | <what was settled> | <the reasoning, including what was rejected> | <name> |
```

Record the rejected option, not just the chosen one — "we used static designs" is far less useful later than "the client asked for animation; the signed scope excludes it, so animation is separately scoped."

Log decisions, not commercial terms. *"Animation excluded by contract"* belongs here; *what it would cost to add* does not.

## Stage 4 — Verify before sharing

Two checks, both cheap, both catching failures that are silent otherwise.

**Redaction.** Run `redaction-audit.sh` over the folder, passing the sensitive strings you read in the contract:

```bash
./redaction-audit.sh "<project folder>" "£500" "58217" "<client name>"
```

It scans every `.md` for those literals plus built-in patterns — currency amounts, payment language, email addresses, contract IDs — and prints `CLEAN` or `FAIL` with file and line. Generated PDFs mirror their markdown source, so markdown coverage is enough. Review each hit: some are legitimate, most are not. **Do not share the folder until this passes.**

**Rendering.** For any right-to-left PDF, rasterize and look at it — see MECHANICS.md. Extracted text is not evidence, and neither is a glance: check the word order of every multi-word Latin run against the source. Client and product names are exactly what breaks.

## Stage 5 — Seed the tracker

Bare minimum on purpose. The lead breaks it down, not you.

- **One project per team** when each should see only their own board. When they should share a board instead, use a single project and split the phases with milestones.
- Cross-link the projects in both descriptions **after** creation — the URLs don't exist until then, so this is a second update pass.
- **A bold note at the top of every project description**: seeded deliberately thin, the named lead owns the breakdown, and where the full brief lives.
- **At most two issues per project**: the unblocking action (usually the client kickoff call), and a "break this down" issue assigned to that team's lead.
- **Link sequential phases as real dependencies**, not prose — on the *issue*, so it surfaces on the blocked team's board (`save_issue` with `blockedBy`).
- **No fee or contract detail anywhere in the tracker.**

Duplicate a genuinely shared action — one client call answering questions for two teams — into both boards only when each team should track it independently. Otherwise keep one and reference it.

## Common mistakes

| Mistake | Consequence |
|---|---|
| Briefing from the user's summary instead of the document | Scope is wrong from the first artifact |
| Building on the first contract handed over | The whole briefing rests on superseded scope — deliverables, price, and phases may all have changed |
| Hardcoding one drive account | Project lands in the wrong company's drive; found out when a client asks for access |
| Starting before confirming tracker auth | Half-finished kickoff: folders and briefs exist, tracker is empty |
| Presenting unconfirmed scope as decided | Team designs flows the client never agreed to pay for |
| Copying the client's asset library in | Goes stale silently; team works from outdated characters |
| Seeding a full task breakdown | Overrides the lead's judgment — the opposite of what was asked |
| Reporting "done" after writing files | Nobody but you can see the folder until it is shared manually |
| Diagnosing an RTL PDF from extracted text | Correct output looks broken; you rewrite good copy to fix a bug that isn't there. See MECHANICS.md |
| Skimming a rendered RTL page instead of reading it | Multi-word Latin runs reverse while single words look perfect — the client's own name ships backwards |
| Putting commercial terms in the context file | It is designed to be pasted into third-party LLMs — anything in it has left the building |
| Writing the roster into the context file from memory | Assignments go to the wrong people; query the tracker instead |
| Asserting the redaction rather than running the audit | Being careful is not evidence. A leaked fee is silent, and irreversible once shared |
| Writing the decision log after the fact | The reasoning is already gone; you record conclusions and lose the rejected options |
