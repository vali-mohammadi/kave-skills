---
name: graph-notation
description: Reads a numbered notation plan and renders it as a Mermaid decision-tree diagram for visual confirmation before agent execution. Use when the user writes a numbered step plan with operators (|, &, *N, >>, !, ~, @Ns, > < =), wants to visualize an agent graph or workflow, or says "draw the plan" / "confirm the flow" / "show the tree".
---

# Graph Notation

Turns a compact numbered plan into a Mermaid decision tree and a validated execution spec.
The diagram is the contract — nothing runs until the user approves it.

## Notation language

| Symbol | Meaning | Example |
|--------|---------|---------|
| `> < =` | condition/threshold | `complexity > 5` |
| `\|` | branch — pick one route | `refactor \| direct` |
| `&` | parallel — run together | `test & lint` |
| `*N` | repeat N times | `retry *3` |
| `>>` | merge — collect all results | `report >>` |
| `!` | hard requirement — halt on fail | `deploy ! prod` |
| `~ condition` | loop until condition | `fix ~ pass` |
| `@Ns` | timeout in N seconds | `analyze @60s` |

See [NOTATION.md](NOTATION.md) for operator precedence and edge cases. See [EXAMPLES.md](EXAMPLES.md) for 9 worked examples with diagrams.

## Steps

1. **Parse the plan** — read each numbered line, identify operators, label each node type:
   - plain step → `[rect]`
   - condition (`?`) → `{diamond}`
   - parallel (`&`) → split into sibling nodes
   - merge (`>>`) → converge node
   - loop (`~`) → back-edge on the graph

2. **Render the Mermaid diagram** — output a `graph TD` block. Rules:
   - Each step is a node labeled with its action
   - Conditions become diamonds with `yes/no` edges
   - Parallel steps fan out from a split node and converge at the next step
   - Loop edges point back to their origin node with the loop condition as label
   - Timeout appears as a note on the node: `@Ns`
   - Halt (`!`) marks the node red: `style N fill:#f66`

3. **Print the execution spec** — after the diagram, list each node with:
   - node id, action text, type, dependencies, timeout if any

4. **Ask for approval** — "Does this match your intent? Reply yes to proceed or correct any step."

5. **On approval** — output the validated plan in a format `grok-orchestrator` can consume (see [NOTATION.md](NOTATION.md) §handoff).

## Completion criterion

Done when the user has seen the Mermaid diagram, confirmed it matches intent, and the validated plan is ready for `/grok-orchestrator`.
