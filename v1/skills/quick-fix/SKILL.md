---
name: quick-fix
description: Fix a small problem directly, verify it, update docs if needed, and commit when green.
---

You are the orchestrator for one bounded fix in the current repository. The input
is a problem, not a plan. You route the fix through a single implementation
worker, plus an optional review or verification worker — you do not become an
inline implementation skill.

## Bootstrap

Read `~/agent-docs/v1/rules/skill-contracts.md` and run the **Standard Intake
Protocol**: manifest (`code_root`, `change-to-doc`, `drift-gates`,
`drift-verification`) → `index.md` → `overview.md` → stop. The problem to fix is
the task; if it is missing, run the two-question intake and wait.

Once the problem is known, read
`~/agent-docs/v1/rules/orchestrator/lifecycle.md` and
`~/agent-docs/v1/rules/orchestrator/dispatch.md` to classify and dispatch. Load
task-specific architecture/decisions/agent-context docs only when classification
needs them.

## Scope Policy

- Quick fixes can affect any part of the app, but the change stays bounded: one
  bug, one small behavior correction, one small feature, or one obvious cleanup.
- If the issue is too large, ambiguous, or direction-setting for a quick fix,
  pivot to planning: say it needs `/plan`, summarize the concern, ask the
  batched high-level questions, and stop before dispatching implementation.
- Do not leave a partial fix. If it cannot close cleanly, the implementation
  worker leaves the tree coherent and reports the blocker; do not claim it fixed.
- Ask before changing public behavior or APIs only when the problem statement
  does not already imply the desired behavior. At `review-none`, choose the best
  defensible option and note the assumption.

## Worker Phases

Dials and model policy follow `skill-contracts.md`; dispatch shape and commit
concurrency follow `orchestrator/dispatch.md`.

- **Implementation worker** (the fix). Pass the Implementation worker bundle:
  `~/agent-docs/v1/rules/subagent/implementation.md`,
  `~/agent-docs/v1/rules/coding-style.md`,
  `~/agent-docs/v1/rules/authoring-rules.md`,
  `~/agent-docs/v1/rules/repo-rules.md`. It implements, runs the cheapest
  sufficient gate, migrates durable docs only if needed, and commits before
  reporting.
- **Verification worker** only when the implementation worker cannot run the
  right gate or a final manifest gate is better isolated. Pass
  `~/agent-docs/v1/rules/subagent/verification.md` and
  `~/agent-docs/v1/rules/repo-rules.md`.
- **Review worker** only when the fix touches user-facing, cross-cutting, or
  correctness-sensitive behavior. Pass
  `~/agent-docs/v1/rules/subagent/review.md` plus the changed source. For
  UI-facing fixes, ask the worker to do visual verification when practical.

A pure one-line change still goes through the implementation worker — that is the
mutation/gate boundary in `orchestrator/lifecycle.md`, not an inline exception.

## Closeout

Record from worker reports:

- problem fixed and confirmed present in the diff
- files changed
- checks run and result
- docs updated or why none were needed
- commit hash
- any follow-up that remains

$ARGUMENTS
