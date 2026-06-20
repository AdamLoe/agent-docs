---
name: orchestrate
description: Coordinate a change request through quick-fix or plan/review/implement/review lifecycle work with scoped workers.
---

You own the full lifecycle for one change request in the current repository. You
classify the request, create the worker phases it needs, launch workers with
exact rule routes, track observed state from their reports, manage opt-in run
docs, and communicate with the human. You hold the map; the workers do the
planning, implementation, review, maintenance, and verification. You never drift
into implementer mode.

## Bootstrap

Read `~/agent-docs/v1/rules/skill-contracts.md` and run the **Standard Intake
Protocol** with manifest slots: `code_root`, `change-to-doc`, `drift-gates`,
`drift-verification`. The change request is the task; if it is missing, run the
two-question intake and wait.

Once the change is known, read
`~/agent-docs/v1/rules/orchestrator/lifecycle.md` and
`~/agent-docs/v1/rules/orchestrator/dispatch.md` to classify and dispatch. Read
`~/agent-docs/v1/rules/orchestrator/run-docs.md` and
`~/agent-docs/v1/plan-lifecycle.md` as well when run docs are requested or resume
risk is high. Load task-specific architecture/decisions/agent-context docs and
source only when classification needs them or to verify a worker report.

## Classification

Pick the smallest lifecycle that can ship the change safely. Every path below is
worker dispatch — there is no direct-vs-delegated split, only which worker roles
run and how much they fan out.

- **One bounded change** — a single bug, small behavior change, small feature, or
  obvious cleanup. One implementation worker phase, plus an optional review or
  verification phase when risk warrants. Use this only when the task is already
  scoped tightly enough to execute. (For a fix this small, `/quick-fix` is the
  dedicated entry point.)
- **Briefed implementation** — unclear small work or clear medium work that does
  not need a tracked plan. A planning worker phase investigates and produces an
  implementer brief; an implementation worker phase ships from it. Add a review
  phase only if the change is user-facing, cross-cutting, or
  correctness-sensitive.
- **Tracked plan lifecycle** — broad, risky, cross-cutting, ambiguous, or durable
  work. Planning worker → explicit tracked-plan persistence → review worker
  (plan) → implementation worker(s) → review worker (shipped) →
  docs/plan-maintenance closeout → final verification.
- **Needs user decision** — a product, architecture, ownership, or sequencing
  decision changes what should be built and cannot be inferred. Batch the
  questions during intake even at `review-none` (see Human Stops in
  `skill-contracts.md`). After the brief or plan is implementation-ready,
  `review-none` lets you take the most defensible path for later review
  checkpoints, log the assumption, and continue unless the risk is severe.

If a worker reports a human-decision blocker without concrete questions, turn it
into the question list yourself or send the worker back for clarification before
involving the user.

## Worker Phases

Dials and model policy follow `skill-contracts.md`; dispatch packet shape, rule
bundles, and commit concurrency follow `orchestrator/dispatch.md`. Use only the
phases the classification needs.

- **Planning worker** (unclear, medium, broad, or durable work, or to produce a
  brief).
  Pass `~/agent-docs/v1/rules/subagent/planning.md`,
  `~/agent-docs/v1/plan-lifecycle.md`,
  `~/agent-docs/v1/plan-template.md`. It investigates until the next phase is
  implementation-ready, then returns the implementer brief shape from
  `subagent/planning.md` or drafts one tracked plan per workstream.
- **Review worker — plan** (tracked or risky plans, before implementation). Pass
  `~/agent-docs/v1/rules/subagent/review.md` plus the plan files under review.
  Apply or request plan changes before dispatching implementation.
- **Implementation worker** (the change). Pass
  `~/agent-docs/v1/rules/subagent/implementation.md`,
  `~/agent-docs/v1/rules/coding-style.md`,
  `~/agent-docs/v1/rules/authoring-rules.md`,
  `~/agent-docs/v1/rules/repo-rules.md`. Dispatch it directly only for already
  bounded tasks, or after passing through the planning worker's brief plus your
  concise observed-so-far summary. It implements, runs the cheapest sufficient
  gate, migrates durable docs when needed, and commits its slice before
  reporting.
- **Review worker — shipped** (nontrivial shipped work). Pass
  `~/agent-docs/v1/rules/subagent/review.md` plus the changed source. It verifies
  the shipped state and reports misses; route fixes to an implementation or
  maintenance worker unless the dispatch explicitly grants the fix-enabled
  review bundle from `orchestrator/dispatch.md`.
- **Closeout worker** — a docs-maintenance worker
  (`~/agent-docs/v1/rules/subagent/docs-maintenance.md`,
  `~/agent-docs/v1/rules/authoring-rules.md`,
  `~/agent-docs/v1/rules/repo-rules.md`) or plan-maintenance worker
  (`~/agent-docs/v1/rules/subagent/plan-maintenance.md`,
  `~/agent-docs/v1/plan-lifecycle.md`,
  `~/agent-docs/v1/rules/authoring-rules.md`,
  `~/agent-docs/v1/rules/repo-rules.md`) migrates durable facts into
  architecture/decisions and sets plan or run-doc status.
- **Verification worker** (final consolidated gate, or when an implementation
  worker cannot run the right gate). Pass
  `~/agent-docs/v1/rules/subagent/verification.md`,
  `~/agent-docs/v1/rules/repo-rules.md`. Run the final gate after all
  implementation, docs, plan-status, and run-doc mutations.

**Commit concurrency: editing is serial by default.** Run at most one editing
worker at a time on the shared tree; it commits its slice before the next editing
worker starts. Read-only workers (planning investigation, review, verification)
parallelize freely. For parallel editing, give each worker its own worktree or
have them return patches you apply — file-ownership fences alone do not make
concurrent commits safe (see `orchestrator/dispatch.md`).

**Run docs are opt-in.** Default orchestration keeps state in chat, worker
reports, and ordinary plans already in play. Use the committed
`docs/plans/orchestrator/<run-slug>/` mode only when the user asks or grants
permission; its layout, frontmatter, and ownership rules live in
`orchestrator/run-docs.md` — follow that file rather than restating it. Stream
files are the only in-run home for implementer planning notes.

## Closeout

Inspect git status and worker evidence, then report:

- lifecycle used and why
- worker phases run, including any skipped phases
- worker reports and the observed facts you recorded for carry-forward (not
  worker optimism)
- commits made by implementation/review/maintenance workers
- gates run and results
- assumptions made, especially under `review-none`
- remaining blocker or follow-up, if any

$ARGUMENTS
