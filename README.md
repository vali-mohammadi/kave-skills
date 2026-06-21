# kave-skills

Agent skills for headless Grok orchestration and graph-based communication.

## Skills

| Skill | Trigger | What it does |
|-------|---------|-------------|
| `/graph-notation` | Describing a plan, workflow, or agent graph | Turns numbered notation into a Mermaid decision tree and a structured plan ready to execute |
| `/grok-orchestrator` | Running the plan | Spawns headless `grok` CLI instances in the topology defined by the plan, verifies at each layer, and merges results |

## Workflow

Use both skills in a single prompt:

```
1. analyze codebase @60s
2. complexity > 5 | refactor *2
3. test & lint
4. coverage > 80% | fix ~ pass
5. report >>
```

`/graph-notation` confirms the plan as a Mermaid diagram.  
`/grok-orchestrator` executes it.

## Notation quick-ref

| Symbol | Meaning | Example |
|--------|---------|---------|
| `> < =` | condition | `complexity > 5` |
| `\|` | branch | `refactor \| direct` |
| `&` | parallel | `test & lint` |
| `*N` | repeat N times | `retry *3` |
| `>>` | merge all results | `report >>` |
| `!` | must succeed or halt | `deploy ! prod` |
| `~ condition` | loop until condition | `fix ~ pass` |
| `@Ns` | timeout | `analyze @60s` |
