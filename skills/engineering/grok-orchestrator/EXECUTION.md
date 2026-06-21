# Execution Reference

## Session naming

Every grok call gets a deterministic session ID so sessions are resumable and auditable:

```
plan-<planId>-<nodeId>          # main node execution
verify-<planId>-<nodeId>        # verifier call
route-<planId>-<nodeId>         # decision routing call
merge-<planId>-<nodeId>         # merge/synthesize call
```

`planId` = 6-char hash of the plan entry timestamp. Generate with: `date +%s | md5 | cut -c1-6`

Sessions stored at `~/.grok/sessions/`.

## Spawn patterns

### Sequential node
```bash
grok -p "<action>" -s "plan-<id>-<node>" \
     --output-format streaming-json \
     --always-approve --no-alt-screen
```

### Parallel nodes (fan-out)
```bash
# Fire all siblings as background processes
grok -p "<action-A>" -s "plan-<id>-<nodeA>" --output-format json --always-approve &
grok -p "<action-B>" -s "plan-<id>-<nodeB>" --output-format json --always-approve &
wait  # converge
```

### With timeout
```bash
timeout <N>s grok -p "<action>" -s "plan-<id>-<node>" \
     --output-format streaming-json --always-approve --no-alt-screen
# Exit code 124 = timeout
```

### With repeat (*N)
```bash
for i in $(seq 1 N); do
  result=$(grok -p "<action>" -s "plan-<id>-<node>-iter$i" \
               --output-format json --always-approve)
  # collect $result
done
```

## Output parsing

`--output-format json` returns a single object at completion. Extract the final message:
```bash
result=$(grok -p "..." --output-format json --always-approve)
text=$(echo "$result" | jq -r '.messages[-1].content // .result // .')
```

`--output-format streaming-json` returns newline-delimited events. Capture last assistant message:
```bash
text=$(grok -p "..." --output-format streaming-json --always-approve \
       | jq -rs '[.[] | select(.type=="assistant")] | last | .content')
```

## Verifier prompt template

Battle-tested rules: verdict is the **first token**, no preamble; judge **strictly** against the goal only (not general quality); **default to FAIL** when the output is missing, truncated, or you are unsure.

```
You are a strict verifier. Judge ONLY whether the output below achieves this goal:
GOAL: "<action>"

Rules:
- First token of your reply MUST be PASS or FAIL — nothing before it.
- PASS only if the goal is fully met. If partial, ambiguous, empty, or truncated → FAIL.
- After FAIL add a colon and one short reason, e.g. FAIL:tests still red.

Output to verify:
<node_output>
```
Parse: read the first whitespace-delimited token. Treat anything other than `PASS` as failure.

## Decision routing prompt template

Same discipline: first-token verdict, no hedging, default to the safer branch (`NO`) when unsure.

```
You are a router. Decide ONLY whether this condition holds for the output below:
CONDITION: "<condition>"

Rules:
- First token of your reply MUST be YES or NO — nothing before it.
- If the output is insufficient to decide → answer NO.

Output:
<node_output>
```
Parse: read the first token. Treat anything other than `YES` as `NO`.

## Mermaid state diagram template
```
graph TD
  n1[analyze @60s]:::done
  n2{complexity > 5?}:::active
  n3[refactor *2]:::pending
  n4[direct]:::pending
  n5[test]:::pending
  n6[lint]:::pending
  n7[report >>]:::pending

  n1 --> n2
  n2 -->|yes| n3
  n2 -->|no| n4
  n3 --> n5
  n4 --> n5
  n5 & n6 --> n7

  classDef done fill:#9f9,stroke:#393
  classDef active fill:#ff9,stroke:#993
  classDef pending fill:#eee,stroke:#999
  classDef failed fill:#f66,stroke:#933
```

## Environment
- `XAI_API_KEY` must be set
- `--no-auto-update` recommended in orchestration contexts (or set `auto_update = false` in `~/.grok/config.toml`)
