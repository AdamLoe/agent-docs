---
name: ship-current-work
description: Finish ordinary work by inspecting the diff, updating owned docs, running the manifest drift gates, and committing if green.
---

You are the orchestrator for finishing the current dirty tree in this
repository. You coordinate finalization — inspection, docs migration,
verification, and commit — by dispatching workers; you do not inspect every diff
hunk or run gates inline.

## Bootstrap

Read `~/agent-docs/v1/rules/skill-contracts.md` and run the **Standard Intake
Protocol** with manifest slots: `code_root`, `change-to-doc`, `drift-gates`,
`drift-verification`, `decisions-domains`.

This skill is **state-driven**: it runs directly off the current git state, with
no two-question intake. Read `docs/_meta/ownership.json` and the current
`git status --short`, `git diff --stat`, and `git diff --name-only` inline —
that is coordination routing, not worker dispatch. Honor any dials passed in
`$ARGUMENTS`. If the tree is clean, say so and stop.

Once you know what changed, read
`~/agent-docs/v1/rules/orchestrator/lifecycle.md` and
`~/agent-docs/v1/rules/orchestrator/dispatch.md` to choose worker phases and
dispatch. Resolve owning docs from `change-to-doc` plus `ownership.json`.

## Worker Phases

Dials and model policy follow `skill-contracts.md`; dispatch shape, bundles, and
commit concurrency follow `orchestrator/dispatch.md`. Editing workers are serial
on the shared tree. Use only the phases the diff needs. Run final verification
after all implementation, docs, plan-status, and run-doc mutations.

- **Review worker** (inspect the diff). Pass
  `~/agent-docs/v1/rules/subagent/review.md` plus the changed source and the
  manifest/ownership facts. It confirms the requested outcome is present and
  flags missing docs or tests.
- **Docs-maintenance worker** when the change carries durable facts or rationale.
  Pass `~/agent-docs/v1/rules/subagent/docs-maintenance.md` and
  `~/agent-docs/v1/rules/authoring-rules.md`, and
  `~/agent-docs/v1/rules/repo-rules.md`. It updates owning
  architecture/decisions docs in place.
- **Plan-maintenance worker** only when a plan was touched or completed. Pass
  `~/agent-docs/v1/rules/subagent/plan-maintenance.md`,
  `~/agent-docs/v1/plan-lifecycle.md`, and
  `~/agent-docs/v1/rules/authoring-rules.md`, and
  `~/agent-docs/v1/rules/repo-rules.md`. It migrates durable plan context
  first, then sets `status`, `last_updated`, and `okay_to_delete` truthfully. Do
  not delete plans here.
- **Implementation worker** only when the review surfaces obvious missing work
  that must be fixed before shipping. Pass
  `~/agent-docs/v1/rules/subagent/implementation.md`,
  `~/agent-docs/v1/rules/coding-style.md`,
  `~/agent-docs/v1/rules/authoring-rules.md`, and
  `~/agent-docs/v1/rules/repo-rules.md`. It implements, gates, and commits its
  slice. Substantial new work is out of scope — flag it for `/plan` or
  `/quick-fix` instead.
- **Verification worker** to run the targeted gate plus the manifest
  `drift-gates`. Pass `~/agent-docs/v1/rules/subagent/verification.md` and
  `~/agent-docs/v1/rules/repo-rules.md`.

Editing workers stage by filename and commit their own slice before reporting;
record the hashes and verify the final green state. Never push unless explicitly
told.

## Closeout

Record from worker reports:

- diff inspected and the requested outcome confirmed present
- docs/plan migration done, or why none was needed
- gates run and result
- commit hash(es)
- any residual risk or follow-up that remains

$ARGUMENTS
