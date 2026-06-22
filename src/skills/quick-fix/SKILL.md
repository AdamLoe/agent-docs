---
name: quick-fix
description: Fix one already bounded problem, verify it, update docs if needed, and commit when green.
---

You are the orchestrator for one already bounded fix in the current repository.
The input is a problem, not a plan. You route the fix through a single
implementation worker, plus an optional review or verification worker. If the
problem needs investigation before it is implementable, route to a planning
worker or `/plan` instead of dispatching implementation.

## Bootstrap

Read `~/.agentdocs/rules/skill-contracts.md` and run the **Standard Intake
Protocol** with manifest slots: `code_root`, `change-to-doc`, `drift-gates`,
`drift-verification`. The problem to fix is the task; if it is missing, run the
two-question intake and wait.

Do NOT pre-load `context-profiles.md`, `dispatch.md`, or `lifecycle.md` at
startup. Load task-specific architecture/decisions/agent-context docs only when
the problem needs them. Dials, model policy, dispatch shape, profiles, and commit
concurrency are covered by `skill-contracts.md` and `orchestrator/dispatch.md`
(see References).

## Scope Policy

- Quick fixes can affect any part of the app, but the change stays bounded: one
  bug, one small behavior correction, one small feature, or one obvious cleanup.
- Dispatch implementation only when the issue is already scoped tightly enough
  to execute. If a small issue needs investigation first, dispatch a planning
  worker for an implementer brief. If it is medium, broad, or direction-setting,
  pivot to `/plan`: summarize the concern, ask the batched high-level questions,
  and stop before implementation.
- Do not leave a partial fix. If it cannot close cleanly, the implementation
  worker leaves the tree coherent and reports the blocker; do not claim it fixed.
- Ask before changing public behavior or APIs only when the problem statement
  does not already imply the desired behavior. At `review-none`, choose the best
  defensible option and note the assumption.

## Worker Phases

Use only the phases the fix needs.

- **Planning worker** (only when the issue is still small but not bounded enough
  to implement). Profile: `planning.brief`. Returns the implementer brief shape;
  then dispatch one implementation worker from that brief.
- **Implementation worker** (the bounded fix). Profile: `implementation.code`,
  escalating to `implementation.code-docs` only when a touched surface requires
  owning-doc migration. Implements, runs the cheapest sufficient gate, migrates
  durable docs only if needed, and commits before reporting.
- **Verification worker** only when the implementation worker cannot run the
  right gate or a final manifest gate is better isolated. Profile:
  `verification.readonly`.
- **Review worker** only when the fix touches user-facing, cross-cutting, or
  correctness-sensitive behavior. Profile: `review.generic` plus the changed
  source. For UI-facing fixes, ask the worker to do visual verification when
  practical.

This skill's kernel workflow is `quick-fix`; `src/kernel/workflows.json` is the
machine authority for its phase sequence and allowed profiles. Workers resolve
their context via `bash src/verify-agent-docs.sh --resolve <profile-id>`.

A pure one-line change still goes through the implementation worker — that is the
mutation/gate boundary, not an inline exception.

## Closeout

Record from worker reports:

- problem fixed and confirmed present in the diff
- files changed
- checks run and result
- docs updated or why none were needed
- commit hash
- any follow-up that remains

## References (do not auto-load)

- `skill-contracts.md` Owner Pointers → dispatch shape, profile IDs, resolver

$ARGUMENTS
