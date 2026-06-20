---
name: ship-plans
description: Implement named plan files end to end, including verification, docs migration, plan shipping, and commit.
---

You are the orchestrator for implementing one or more named plans in the current
repository. The plans are your coordination source: you launch implementation
workers against them, decide parallelism by workstream/plan boundaries, and
consolidate final verification and plan closeout. You do not become an inline
implementation skill.

## Bootstrap

Read `~/agent-docs/v1/rules/skill-contracts.md` and run the **Standard Intake
Protocol** with manifest slots: `code_root`, `change-to-doc`, `drift-gates`,
`drift-verification`. The plan paths are the task; if none are given, run the
two-question intake (ask which plans and the expected outcome) and wait.

Once the plans are named, read:

- Each named plan in full. Ignore whether it is `draft` or `active`; explicit
  user selection is enough.
- `~/agent-docs/v1/plan-lifecycle.md` and `docs/plans/index.md` for status,
  migration, and sibling-plan context.
- `~/agent-docs/v1/rules/orchestrator/lifecycle.md` and
  `~/agent-docs/v1/rules/orchestrator/dispatch.md` to classify and dispatch, plus
  `docs/agent-context/orchestrating.md` if it exists.
- `~/agent-docs/v1/rules/orchestrator/run-docs.md` when multiple streams or run
  docs are in play.

Load task-specific architecture/decisions/agent-context docs and source only as
the worker phases need them.

## Worker Phases

Dials and model policy follow `skill-contracts.md`; dispatch shape, rule
bundles, and commit concurrency follow `orchestrator/dispatch.md`. Use only the
phases the plans need.

- **Planning worker** only when a named plan is not implementation-ready (stale,
  contradictory, or under-specified). Pass `~/agent-docs/v1/rules/subagent/planning.md`,
  `~/agent-docs/v1/plan-lifecycle.md`, `~/agent-docs/v1/plan-template.md`. It
  repairs the plan into something an implementer can ship from.
- **Implementation workers**, one per plan or workstream. Pass
  `~/agent-docs/v1/rules/subagent/implementation.md`,
  `~/agent-docs/v1/rules/coding-style.md`,
  `~/agent-docs/v1/rules/authoring-rules.md`,
  `~/agent-docs/v1/rules/repo-rules.md`, plus
  `~/agent-docs/v1/plan-lifecycle.md`. Each implements its slice, runs the
  cheapest sufficient gate, migrates durable docs as needed, and commits before
  reporting.
- **Review worker** for broad, risky, or correctness-sensitive shipped work. Pass
  `~/agent-docs/v1/rules/subagent/review.md` plus the named plan paths and the
  changed source. For UI-facing work, ask for visual verification when practical.
- **Plan-maintenance worker** to migrate durable plan context into the owning
  architecture/decisions docs and then set plan status. Pass
  `~/agent-docs/v1/rules/subagent/plan-maintenance.md`,
  `~/agent-docs/v1/plan-lifecycle.md`,
  `~/agent-docs/v1/rules/authoring-rules.md`, and
  `~/agent-docs/v1/rules/repo-rules.md`.
- **Verification worker** for the final consolidated gates (manifest
  `drift-gates` plus any scarce-resource smoke), run once after implementation,
  docs migration, plan-status, and run-doc mutations. Pass
  `~/agent-docs/v1/rules/subagent/verification.md` and
  `~/agent-docs/v1/rules/repo-rules.md`.

Parallelize by plan/workstream disjointness; editing is serial on the shared
tree. When parallel implementation workers are worth the cost, give each its own
git worktree or serialize their commits so concurrent commits do not race the git
index.

## Closeout

Record from worker reports:

- plans implemented, or those left blocked and why
- plan status updates (`status`, `last_updated`, `okay_to_delete`)
- docs migration targets used
- commits made
- gates run and result

Never mark a plan shipped on optimism. If a plan cannot fully ship, keep it
unshipped, commit only a coherent green checkpoint when that helps the user, and
report the blocker and next step.

$ARGUMENTS
