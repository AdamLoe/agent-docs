---
wave: 3
status: launch-drivers-compressed
commit: (see below)
---

# Wave 3 pilot stream — compress lifecycle.md via reference-leaf relocation

## Pilot scope

One file: `src/rules/orchestrator/lifecycle.md`. Method: RELOCATE (not delete)
non-normative content to a never-auto-loaded reference leaf, preserving every
invariant. This calibrates whether the aggressive Wave 3 budget is reachable.

## Before → after

- `src/rules/orchestrator/lifecycle.md`: **1826 → 1037 words** (−789).
- New reference leaf: `src/rules/orchestrator/lifecycle-reference.md`, **1318
  words** (under the 2200-word per-file orchestrator-rule verifier budget; never
  auto-loaded).

## Was <=500 reachable by relocation only, with no correctness loss?

**No.** The honest correctness floor is ~1037 words. Everything below the floor
is normative contract, not relocatable explanation. To reach 500 I would have to
delete ~520 words of actual rules. Per-section accounting (post-trim):

| Section | Words | Kind |
|---|---:|---|
| Intro / routing scaffold | 63 | required pointers |
| Orchestrator/worker split | 36 | rule |
| Reads vs. dispatch | 142 | rule (4 dispatch triggers + inline + spawn-fail-stop) |
| Classification | 142 | rule (5-option lifecycle ladder) |
| Effort dials | 80 | rule (6 gate-pinned dial tokens + resolution) |
| Your job | 113 | rule (map/verify/notes invariants) |
| Ship-order checkpoints | 140 | rule (9 checkpoints incl. final-gate-after-last-mutation) |
| Sequencing | 79 | rule (one-consumer-per-scarce-resource, serial editing) |
| Human stops | 63 | rule |
| Invariants — what NOT to do | 98 | rule (no implementer drift, no full-suite-per-stream, etc.) |
| See also | 48 | non-loading pointers |

## What was relocated vs. kept

**Relocated to `lifecycle-reference.md` (explanation only):**

- the orchestrator "responsible for" bullet expansion;
- the reads-vs-dispatch worked examples (`start-session` inline vs. dispatch;
  `list-skills`/`feedback-agent-docs` as inline utilities; "don't invent a
  one-line worker");
- the full effort-dial table (fan-out / worker-output budget / model spend per
  tier) and its surrounding commentary;
- the expanded "Your actual job" prose;
- the "Bringing in second opinions" rationale paragraph;
- the "Workflow skeleton" walk-through, including the streams-table column
  example;
- the expanded "what NOT to do" prose with parentheticals.

**Kept in runtime `lifecycle.md` (normative contract):**

- orchestrator/worker split rule;
- reads-vs-dispatch test: the 4 dispatch triggers, inline-when-none rule, and the
  spawn-failure stop rule;
- the 5-option classification ladder (incl. selected-plan-closeout ownership and
  read-only review/verification);
- effort-dial resolution + all 6 gate-required dial tokens
  (`cost-low/medium/high/max`, `review-none`, `review-high`);
- the three "your job" invariants (hold the map; verify outcomes not steps;
  resumable notes);
- the 9 ship-order checkpoints + "no workflow is green until the final gate
  observes state after the last mutation";
- sequencing invariants (one-consumer-per-scarce-resource; serial editing /
  parallelize-by-disjointness);
- human-stop rule;
- the four "what NOT to do" invariants;
- non-loading `See also` pointers, including the leaf pointer.

A reader of the compressed file can still follow the contract correctly without
the leaf.

## Never-auto-loaded confirmation

`rg -l "lifecycle-reference" src/skills src/rules` → only `lifecycle.md`. Not in
any `context-profiles.md` core_rule_paths. The launch loop in
`verify-agent-docs.sh` counts only `lifecycle.md`, so the leaf adds zero launch
cost.

## Launch impact

`bash src/verify-agent-docs.sh --measure-launch orchestrate`:
**TOTAL 5542 → 4753** (lifecycle line 1826 → 1037). MEASURE-LAUNCH PASS.

## Gate

`bash src/verify-agent-docs.sh` → exit 0, `ALL AGENT-DOCS GATES PASS`.

## Calibration verdict for the remaining 8 files

The <=500 target for `lifecycle.md` is **not reachable by relocation alone**;
this file is a dense normative contract, so its floor (~1037) is roughly 2x the
target. This is the "target requires a decision" case from the plan — do NOT cut
correctness to hit 500. For the other Wave-3 files, the relocation method should
land much closer to (or under) target for files whose bulk is examples / dial
tables / anti-pattern catalogues / language idioms (e.g. authoring runtime rules,
coding-style, the dial-table portion of context-profiles). Files that are mostly
pure contract — `lifecycle.md`, parts of `dispatch.md`, the invariant core of
the role cards — will hit a correctness floor above their listed target the same
way this one did. Recommend the user either accept lifecycle at ~1037 (with this
decision recorded) or relax that one budget; the per-file budgets that assume
"all bulk is relocatable explanation" do not hold for the contract-dense files.

---

# Wave 3 continued — compress the three launch-driver rules

Same RELOCATE method as the pilot, applied to the contract-dense files loaded at
every skill startup. Decision E3 in force: relocate maximally with zero
correctness loss; do NOT delete real rules to hit a number — report the floor.

## Per-file before → after + reachability + floor

| File | Before | After | Aspirational target | Reachable by relocation alone? |
|---|---:|---:|---:|---|
| `src/rules/skill-contracts.md` | 831 | 637 | 250 | **No** |
| `src/rules/orchestrator/dispatch.md` | 929 | 811 | 300 | **No** |
| `src/rules/context-profiles.md` | 512 | 533 | 350 | **No** |

Reference leaves (NEVER auto-loaded — pointer only in the parent):

- `src/rules/skill-contracts-reference.md` (855 w, generic-rule cap 1800)
- `src/rules/orchestrator/dispatch-reference.md` (1106 w, orchestrator cap 2200)
- `src/rules/context-profiles-reference.md` (568 w, generic-rule cap 1800)

`rg -l "<leaf>" src/skills src/rules` → each leaf appears ONLY in its parent
file's pointer; none is a profile `core_rule_paths` entry; launch loop counts
none. Confirmed never-auto-loaded.

## Correctness floors (what blocks going lower)

- **skill-contracts ~630.** Relocated: intake "why cache-first", branch examples,
  dial migration/rationale, model-policy rationale, owner-pointer prose. KEPT
  (normative startup contract a worker needs at decision time): the 4-step intake
  order + the stop rule, the two intake branches, both dials + resolution + the
  two gate-checked dial-vocab needles, model-policy roles + escalation triggers,
  human-stops, verification-fallback, owner pointers. These are rules, not
  examples; 250 would require deleting contract.
- **dispatch ~810.** Relocated: the Standard Preamble checklist (orchestrator
  bakes it into prompts — not a decision-time dispatch rule), all rationale, and
  packet-field "why". KEPT (explicit preserve-list): the dispatch-packet field
  block verbatim (the machine the orchestrator fills), context-profile use, the
  full Worker Reports field list incl. invalidation conditions, mutation
  authority + `plan_closeout` grant, resume rule, dispatch-failure stop,
  commit-concurrency / serial-editing rule. 300 would require deleting field
  lists.
- **context-profiles ~530.** Almost nothing is relocatable: the Profiles table
  alone is 285 words of machine-checked contract (verifier parses 11 rows,
  validates mutation/budget/status), plus the Owner Contract field list and the
  untouched Scenario-fixture pointer (`bounded-quick-fix` needle). Only the
  budget-exception / enforcement / scenario rationale moved to the leaf. Net +21
  vs. baseline because the pointer + two load-bearing parentheticals
  (review/verification read-only, enforcement_status gating) were added; 350 is
  unreachable without deleting the table or the field-list contract.

## Launch totals (both drop by the combined −291)

- `--measure-launch quick-fix`: **3303 → 3012**. MEASURE-LAUNCH PASS.
- `--measure-launch orchestrate`: **4753 → 4462**. MEASURE-LAUNCH PASS.
  (skill-contracts −194, dispatch −118, context-profiles +21.)

## Gate

- `bash src/verify-agent-docs.sh` → exit 0, `ALL AGENT-DOCS GATES PASS`.
- `bash src/verify-agent-docs.sh --context-report` → exit 0, `CONTEXT REPORT PASS`.
- `--context-report --profile implementation.code` / `implementation.tracked`
  → exit 0 (still report-only over-budget on profile core files owned by other
  workers; untouched here — no `budget_words` / `enforcement_status` changed).

## Verdict

Like the lifecycle pilot, these are contract-dense launch drivers whose floors
(~630 / ~810 / ~530) sit above target. The combined −291 is the honest relocation
ceiling; the budget-reconciliation step should raise these per-file budgets to
their floors rather than cut correctness.
