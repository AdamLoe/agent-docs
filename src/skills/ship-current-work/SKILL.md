---
name: ship-current-work
description: Finish ordinary work by inspecting the diff, updating owned docs, running the manifest drift gates, and committing if green.
---

You are the orchestrator for finishing the current dirty tree in this
repository. You coordinate finalization — inspection, docs migration,
verification, and commit — by dispatching workers; you do not inspect every diff
hunk or run gates inline.

## Bootstrap

Read `~/.agentdocs/rules/skill-contracts.md` and run the **Standard Intake
Protocol** with manifest slots: `code_root`, `change-to-doc`, `drift-gates`,
`drift-verification`, `decisions-domains`.

This skill is **state-driven**: it runs directly off the current git state, with
no two-question intake. Read `docs/_meta/ownership.json` and the current
`git status --short`, `git diff --stat`, and `git diff --name-only` inline —
that is coordination routing, not worker dispatch. Honor any dials passed in
`$ARGUMENTS`. If the tree is clean, say so and stop.

Do NOT pre-load `context-profiles.md`, `dispatch.md`, or `lifecycle.md` at
startup. Resolve owning docs from `change-to-doc` plus `ownership.json` once
you know what changed.

## Worker Phases

Use only the phases the diff needs. Run final verification after all
implementation, docs, plan-status, and run-doc mutations.

- **Review worker** (inspect the diff). Profile: `review.generic` plus the
  changed source and the manifest/ownership facts. Confirms the requested
  outcome is present and flags missing docs or tests.
- **Docs-maintenance worker** when the change carries durable facts or rationale.
  Profile: `maintenance.docs`. Updates owning architecture/decisions docs in
  place.
- **Plan-maintenance worker** only when a plan was touched or completed. Profile:
  `maintenance.plan`. Migrates durable plan context first, then sets `status`,
  `last_updated`, and `okay_to_delete` truthfully. Do not delete plans here.
- **Implementation worker** only when the review surfaces obvious missing work
  that must be fixed before shipping. Profile: `implementation.code-docs`.
  Implements, gates, and commits its slice. Substantial new work is out of
  scope — flag it for `/plan` or `/quick-fix` instead.
- **Verification worker** to run the targeted gate plus the manifest
  `drift-gates`. Profile: `verification.readonly`.

This skill's kernel workflow is `ship-current-work`; `src/kernel/workflows.json`
is the machine authority for its phase sequence and allowed profiles. Each
dispatch names that profile's exact rule files directly; `--resolve` is a
source-only authoring aid, not a runtime worker step.

## Closeout

Record from worker reports:

- diff inspected and the requested outcome confirmed present
- docs/plan migration done, or why none was needed
- gates run and result
- commit hash(es)
- any residual risk or follow-up that remains

## References (do not auto-load)

- `skill-contracts.md` Owner Pointers → dispatch shape, profile IDs, resolver

$ARGUMENTS
