---
wave: 3
status: pilot-complete
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
