---
name: grok-orchestrator
description: Executes a validated graph-notation plan by spawning headless `grok` CLI instances — one per node — coordinating them in layers (sequential, parallel, branching, looping) and verifying results before advancing. Use when the user has an approved EXEC_PLAN from graph-notation and wants to run it, or says "run the plan" / "execute" / "spawn grok" / "go".
metadata:
  author: kave
  version: "1.0.0"
---

# Grok Orchestrator

Reads a validated `EXEC_PLAN` and drives headless `grok` instances through it layer by layer.
Each layer completes before the next fires. Decisions route the path. Failures halt or retry per node config.

See [EXECUTION.md](EXECUTION.md) for spawn patterns, session naming, and output parsing.

## Steps

1. **Ingest plan** — read the `EXEC_PLAN` JSON (from `/graph-notation` output or inline). Resolve the node graph: find `entry`, map dependencies, group into layers (nodes with no unmet deps = same layer). Generate a `planId` for session naming: `planId=$(date +%s | md5 | cut -c1-6)`. Every grok call is tagged `<role>-<planId>-<nodeId>` where role ∈ `plan|verify|route|merge` (see [EXECUTION.md](EXECUTION.md)).

2. **Render layer map** — print a Mermaid diagram showing current execution state before starting:
   - pending nodes: default style
   - active nodes: `style N fill:#ff9` (yellow)
   - done nodes: `style N fill:#9f9` (green)
   - failed nodes: `style N fill:#f66` (red)

3. **Execute layer by layer** — for each layer:

   a. **Spawn** — for each node in the layer, run:
      ```
      grok -p "<action>" \
           -s "plan-<planId>-<nodeId>" \
           --output-format streaming-json \
           --always-approve \
           --no-alt-screen
      ```
      Apply `--cwd` if node specifies a working dir. Set timeout via `timeout <N>s grok ...`.

   b. **Stream and parse** — collect `streaming-json` events. Extract the final assistant message as the node result.

   c. **Verify** — after each node, run a lightweight verifier:
      ```
      grok -p "Verify this result meets the goal '<action>'. Reply PASS or FAIL:<reason>. Result: <output>" \
           -s "verify-<nodeId>" \
           --output-format json \
           --always-approve
      ```
      Verdict is the **first token**; treat anything other than `PASS` as failure (default-to-FAIL on empty/truncated output). Use the strict [EXECUTION.md](EXECUTION.md) verifier template. On failure: retry up to node's `repeat` count, then halt if `!` flag set.

   d. **Route decisions** — for `decision` nodes, pass the result to a routing call:
      ```
      grok -p "Given this result, does '<condition>' hold? Reply YES or NO. Result: <output>" \
           -s "route-<nodeId>" --output-format json --always-approve
      ```
      First token only; treat anything other than `YES` as `NO` (default to the safer `no` edge when unsure). Follow that edge in the node graph.

   e. **Update diagram** — re-render the Mermaid map with updated node colors after each layer.

4. **Handle loops** — for `loop` nodes: re-execute the node, then run the loop condition check. Back-edge fires if condition fails. Max iterations = `repeat` (default 5) to prevent infinite loops.

5. **Merge** — for `merge` nodes: collect all sibling results into one context and run:
   ```
   grok -p "Synthesize these results into one coherent output: <results>" \
        -s "merge-<nodeId>" --output-format json --always-approve
   ```

6. **Final report** — print the merged output, total nodes run, pass/fail counts, and a final green-state Mermaid diagram.

## Completion criterion

Done when all nodes in the graph have reached a terminal state (done or failed) and the final report has been printed.
