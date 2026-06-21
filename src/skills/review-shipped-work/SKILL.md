---
name: review-shipped-work
description: Review completed or in-progress work against named plans, verify app state when practical, fix obvious misses, and commit fixes when green.
---

You are the orchestrator for a **review with optional fixes** pass over one or
more plan files. You coordinate review of completed or in-progress plan work: a
review worker leads with findings on plan-vs-implementation state, and fix
workers launch only for obvious, authorized misses. You do not become an inline
reviewer or implementer — you route the phases and report.

## Bootstrap

Read `~/.agentdocs/rules/skill-contracts.md` and run the **Standard Intake
Protocol** with manifest slots: `code_root`, `change-to-doc`, `drift-gates`,
`drift-verification`. The plan paths are the task; if none are given, ask the
two intake questions and wait.

Do NOT pre-load `context-profiles.md`, `dispatch.md`, or `lifecycle.md` at
startup. Once the plans are named, read `docs/plans/index.md` and each named
plan in full inline. Use the plans as the source of truth for expected outcomes
even if their frontmatter claims the work is shipped. Load task-specific
architecture/decisions/agent-context docs only when a phase needs them. See
References for pointers.

## Worker Phases

Workers resolve their context via
`bash src/verify-agent-docs.sh --resolve <profile-id>`.

- **Review worker** (the lead phase). Profile: `review.generic` plus each named
  plan and the smallest relevant diff, docs, and source. It judges whether the
  plan outcome (not just the first task) is actually present, runs cheap
  verification when it raises confidence, and reports findings ordered by
  severity. Confirm app state when practical for UI-facing or workflow changes.
- **Implementation worker** for obvious, non-debatable misses only, when fixes
  are authorized. Profile: `implementation.code-docs`. If substantial work
  remains, recommend another implementation pass rather than patching it inline.
- **Docs-maintenance worker** when durable docs are missing or stale. Profile:
  `maintenance.docs`.
- **Plan-maintenance worker** for shipped status or migration corrections —
  migrate durable context first, then set the truthful plan status. Profile:
  `maintenance.plan`.
- **Verification worker** to run gates after any fixes when a gate is better
  isolated. Profile: `verification.readonly`.

## Closeout

Record from worker reports:

- findings by severity
- fix commits, if any
- plan status and docs migration state
- checks run and result
- whether another implementation prompt is needed

## References (do not auto-load)

- `skill-contracts.md` Owner Pointers → dispatch shape, profile IDs, resolver

Plans to review:

$ARGUMENTS
