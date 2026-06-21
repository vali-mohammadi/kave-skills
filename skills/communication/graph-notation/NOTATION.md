# Notation Reference

## Operator precedence (highest → lowest)

1. `@Ns` — timeout (binds to its step only)
2. `!` — halt modifier (binds to its step only)
3. `~ condition` — loop (wraps a step)
4. `*N` — repeat (wraps a step)
5. `&` — parallel (joins steps on same line)
6. `|` — branch (splits from a condition line)
7. `> < =` — condition (used inside `?` lines)

## Condition lines

A line ending in `?` is a decision node. Write the condition after it:

```
2. split? complexity > 5 | direct
```

Becomes: diamond node with two edges — `complexity > 5` → split, else → direct.

## Handoff format (for grok-orchestrator)

After user approval, output a JSON block tagged `EXEC_PLAN`:

```json
// EXEC_PLAN
{
  "nodes": [
    { "id": "n1", "action": "analyze codebase", "type": "step", "timeout": 60 },
    { "id": "n2", "action": "split?", "type": "decision",
      "condition": "complexity > 5",
      "yes": "n3", "no": "n4" },
    { "id": "n3", "action": "refactor", "type": "step", "repeat": 2 },
    { "id": "n4", "action": "direct", "type": "step" },
    { "id": "n5", "action": "test", "type": "parallel", "siblings": ["n6"] },
    { "id": "n6", "action": "lint", "type": "parallel", "siblings": ["n5"] },
    { "id": "n7", "action": "coverage", "type": "decision",
      "condition": "coverage > 80",
      "yes": "n9", "no": "n8" },
    { "id": "n8", "action": "fix", "type": "loop", "until": "pass", "next": "n7" },
    { "id": "n9", "action": "report", "type": "merge" }
  ],
  "entry": "n1"
}
```

## Samples

### Sample 1 — code review pipeline
```
1. analyze PR @60s
2. complexity > 5? | simple
3. review & suggest
4. approve ! merge
5. report >>
```

### Sample 2 — multi-agent content
```
1. research topic @30s
2. draft *3
3. quality > 8? | revise ~ quality > 8
4. edit & proofread
5. publish >>
```

### Sample 3 — deployment pipeline
```
1. build @120s
2. test & lint
3. coverage > 80? | fix *3
4. staging deploy !
5. smoke test ~ pass
6. prod deploy !
7. notify >>
```

### Sample 4 — agent spawning graph
```
1. intake brief @30s
2. scope? large > 3 agents | small
3. agent-A & agent-B & agent-C
4. verify each *2
5. conflicts? detected | clean
6. resolve ~ clean
7. merge >>
```
