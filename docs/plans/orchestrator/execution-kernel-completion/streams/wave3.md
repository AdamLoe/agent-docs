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

## Correctness floors

- **skill-contracts ~630:** relocated rationale/examples; KEPT 4-step intake, both dials + gate-checked needles, model-policy, human-stops, owner pointers. 250 would delete contract.
- **dispatch ~810:** relocated preamble checklist + rationale; KEPT packet fields verbatim, mutation authority, invalidation conditions, commit-concurrency rule. 300 would delete field lists.
- **context-profiles ~530:** table alone is 285 w machine-checked contract; only rationale relocated. Net +21 vs baseline; 350 unreachable without deleting table.

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

## Verdict + Wave 3 continued

Contract-dense; −291 is the relocation ceiling; raise budgets to floors.

Profile-driver rules (profile words before→after): authoring 1428→793, repo-rules
755→429, coding-style 608→353 (Rust/Python/frontend idioms split into conditional
overlays `coding-style-rust.md`, `-python.md`, `-frontend.md` in implementation
profiles), plan-lifecycle 653→427, plan-template 244→223. Reference leaves:
`authoring-rules-reference.md`, `repo-rules-reference.md`, `plan-lifecycle-reference.md`.
Profile resolved-words: implementation.code 1859→1278, .code-docs 3287→2071,
.tracked 3940→2498, maintenance.docs 2532→1571, maintenance.plan 3203→2016,
review.docs 1783→1148, planning.tracked 2115→1542. Gate: exit 0,
ALL AGENT-DOCS GATES PASS + CONTEXT REPORT PASS.

---

# Wave 3 close — reconcile 3 profile budgets to measured floors (E3)

3 profiles remained above budget after full relocation; residual is irreducible normative
contract. Per E3: raise to floor + headroom (no rule deletion).

| Profile | Old → New | Floor |
|---|---|---:|
| `planning.tracked` | 1300 → 1600 | 1542 |
| `review.docs` | 1000 → 1200 | 1148 |
| `maintenance.plan` | 1800 → 2100 | 2016 |

All three: relocated content fully exhausted; residual is normative contract.
Per E3: documented target change, not inflation. Other 8 profiles untouched.

`bash src/verify-agent-docs.sh --context-report` → exit 0, CONTEXT REPORT PASS.
All 11 profiles: `budget_exception: none`.
