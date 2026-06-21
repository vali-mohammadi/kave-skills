# Graph Notation — Examples

Progressive examples from simple to complex.
Each example shows: the notation, the Mermaid diagram it produces, and what actually runs.

---

## 1. Linear pipeline (no operators)

The simplest possible plan — steps run one after another.

```
1. read the codebase
2. summarize architecture
3. write report
```

```mermaid
graph TD
  n1[read the codebase]
  n2[summarize architecture]
  n3[write report]
  n1 --> n2 --> n3
```

**What runs:** three grok calls in sequence. Output of each feeds into the next.

---

## 2. Timeout — `@Ns`

Adds a hard time limit to any step. Useful for tasks that might hang.

```
1. scrape competitor sites @120s
2. extract pricing data
3. write comparison
```

```mermaid
graph TD
  n1["scrape competitor sites\n@120s"]
  n2[extract pricing data]
  n3[write comparison]
  n1 --> n2 --> n3
```

**What runs:** step 1 is killed after 120 seconds if not done. Step 2 gets whatever was collected.

---

## 3. Branch — `|`

A condition line ending in `?` with two routes separated by `|`.

```
1. analyze PR
2. size > 300 lines? | small
3. split into chunks *3
4. review
```

```mermaid
graph TD
  n1[analyze PR]
  n2{size > 300 lines?}
  n3[split into chunks *3]
  n4[small — review directly]
  n5[review]

  n1 --> n2
  n2 -->|yes| n3
  n2 -->|no| n4
  n3 --> n5
  n4 --> n5
```

**What runs:** grok analyzes the PR, a routing call checks the condition, then one of the two branches fires.

---

## 4. Parallel — `&`

Steps on the same line joined by `&` run at the same time.

```
1. build project @90s
2. run tests & run linter & check types
3. all passed? | fix *2
4. deploy >>
```

```mermaid
graph TD
  n1["build project @90s"]
  n2[run tests]
  n3[run linter]
  n4[check types]
  n5{"all passed?"}
  n6["fix *2"]
  n7[deploy >>]

  n1 --> n2 & n3 & n4
  n2 & n3 & n4 --> n5
  n5 -->|yes| n7
  n5 -->|no| n6
  n6 --> n7
```

**What runs:** three grok instances spawn simultaneously after the build. They converge at the condition check.

---

## 5. Repeat — `*N`

Runs the same step N times independently. Useful for getting multiple takes.

```
1. read brief @30s
2. draft proposal *3
3. best draft? score > 7 | revise
4. polish
5. deliver >>
```

```mermaid
graph TD
  n1["read brief @30s"]
  n2a["draft proposal — run 1"]
  n2b["draft proposal — run 2"]
  n2c["draft proposal — run 3"]
  n3{"best draft\nscore > 7?"}
  n4[revise]
  n5[polish]
  n6[deliver >>]

  n1 --> n2a & n2b & n2c
  n2a & n2b & n2c --> n3
  n3 -->|yes| n5
  n3 -->|no| n4
  n4 --> n5 --> n6
```

**What runs:** three independent drafts are generated, then a verifier picks the best one.

---

## 6. Loop — `~ condition`

Keeps repeating until a condition is met. Max 5 iterations by default.

```
1. run test suite @60s
2. tests pass? ~ pass | debug
3. debug ~ pass
4. merge !
```

```mermaid
graph TD
  n1["run test suite @60s"]
  n2{"tests pass?"}
  n3["debug"]
  n4["merge !"]

  n1 --> n2
  n2 -->|pass| n4
  n2 -->|fail| n3
  n3 -->|loop back| n2

  style n4 fill:#f66,stroke:#933
```

**What runs:** grok runs tests, verifier checks pass/fail, if fail it debugs and loops back to re-run tests. Halts the whole plan on merge failure (`!`).

---

## 7. Merge — `>>`

Collects results from multiple branches or steps into one synthesized output.

```
1. research topic — history @30s
2. research topic — current @30s
3. research topic — future @30s
4. synthesize >>
5. write article
```

```mermaid
graph TD
  n1["history research @30s"]
  n2["current research @30s"]
  n3["future research @30s"]
  n4["synthesize >>"]
  n5[write article]

  n1 & n2 & n3 --> n4 --> n5
```

**What runs:** three parallel grok research calls, their outputs merged by a synthesis call, then the article is written from the merged context.

---

## 8. Halt — `!`

Marks a step as a hard requirement. The plan stops completely if it fails.

```
1. run security scan @60s
2. vulnerabilities = 0? | patch ~ clean
3. staging deploy !
4. smoke test *3
5. prod deploy !
6. notify >>
```

```mermaid
graph TD
  n1["run security scan @60s"]
  n2{"vulnerabilities = 0?"}
  n3["patch ~ clean"]
  n4["staging deploy !"]
  n5["smoke test *3"]
  n6["prod deploy !"]
  n7["notify >>"]

  n1 --> n2
  n2 -->|yes| n4
  n2 -->|no| n3
  n3 -->|loop until clean| n2
  n4 --> n5 --> n6 --> n7

  style n4 fill:#f66,stroke:#933
  style n6 fill:#f66,stroke:#933
```

**What runs:** security scan loops until clean, then each `!` step will abort the entire plan on failure — staging failure prevents prod deploy.

---

## 9. Full orchestration — all operators

```
1. intake brief @30s
2. scope? agents > 3 | solo
3. spawn researcher & spawn writer & spawn critic
4. first draft >>
5. quality > 8? | revise ~ quality > 8
6. final review !
7. publish >>
```

```mermaid
graph TD
  n1["intake brief @30s"]
  n2{"agents > 3?"}
  n2s[solo agent]
  n3a[researcher]
  n3b[writer]
  n3c[critic]
  n4["first draft >>"]
  n5{"quality > 8?"}
  n6["revise ~ quality > 8"]
  n7["final review !"]
  n8["publish >>"]

  n1 --> n2
  n2 -->|yes| n3a & n3b & n3c
  n2 -->|no| n2s
  n3a & n3b & n3c --> n4
  n2s --> n4
  n4 --> n5
  n5 -->|yes| n7
  n5 -->|no| n6
  n6 -->|loop| n5
  n7 --> n8

  style n7 fill:#f66,stroke:#933
```

This is a full multi-agent content pipeline: scope check routes to parallel specialist agents or a solo agent, outputs merge, quality loops until threshold, then publishes with a hard gate.

---

## Meta — this repo's own improvement plan

The plan used to generate this file:

```
1. audit current repo @30s
2. examples < 3? | polish only
3. write beginner examples & write advanced examples
4. add walkthrough guide
5. update NOTATION.md >>
```
